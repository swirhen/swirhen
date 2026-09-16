from pathlib import Path
import sqlite3
from typing import Literal

from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel, Field

DB_PATH = Path(__file__).resolve().parents[1] / "nyaatorrent_feed.db"
app = FastAPI(title="Torrent Feed Admin API")

SORT_COLUMNS = {
    "created_at": "created_at",
    "pubdate": "pubdate",
    "category": "category",
    "title": "title",
}


class FeedPatch(BaseModel):
    link: str = Field(min_length=1)
    category: str | None = None
    title: str | None = None
    download_dir: str | None = None
    download_failed_at: str | None = None


def connect() -> sqlite3.Connection:
    connection = sqlite3.connect(DB_PATH)
    connection.row_factory = sqlite3.Row
    return connection


@app.get("/api/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/api/feed-data")
def list_feed_data(
    q: str = "",
    category: str = "all",
    state: Literal["all", "pending", "downloaded"] = "all",
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
    sort: str = "created_at",
    order: Literal["asc", "desc"] = "desc",
) -> dict:
    sort_column = SORT_COLUMNS.get(sort, "created_at")
    conditions: list[str] = []
    parameters: list[str] = []
    if q:
        conditions.append("(title LIKE ? OR link LIKE ?)")
        parameters.extend([f"%{q}%", f"%{q}%"])
    if category != "all":
        conditions.append("category = ?")
        parameters.append(category)
    if state == "pending":
        conditions.append("download_dir IS NULL")
    elif state == "downloaded":
        conditions.append("download_dir IS NOT NULL")

    where = f" WHERE {' AND '.join(conditions)}" if conditions else ""
    offset = (page - 1) * page_size
    with connect() as connection:
        total = connection.execute(
            f"SELECT COUNT(*) FROM feed_data{where}", parameters
        ).fetchone()[0]
        rows = connection.execute(
            f"SELECT category, title, link, pubdate, created_at, download_dir, download_failed_at "
            f"FROM feed_data{where} ORDER BY {sort_column} {order.upper()} LIMIT ? OFFSET ?",
            [*parameters, page_size, offset],
        ).fetchall()
    return {
        "items": [dict(row) for row in rows],
        "total": total,
        "page": page,
        "page_size": page_size,
    }


@app.patch("/api/feed-data")
def update_feed_data(patch: FeedPatch) -> dict[str, str]:
    values = patch.model_dump(exclude_unset=True)
    link = values.pop("link")
    allowed = {key: value for key, value in values.items() if key in {
        "category", "title", "download_dir", "download_failed_at"
    }}
    if not allowed:
        raise HTTPException(status_code=400, detail="No editable fields supplied")
    assignments = ", ".join(f"{key} = ?" for key in allowed)
    with connect() as connection:
        cursor = connection.execute(
            f"UPDATE feed_data SET {assignments} WHERE link = ?",
            [*allowed.values(), link],
        )
        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="Feed item not found")
        connection.commit()
    return {"status": "updated"}


@app.delete("/api/feed-data")
def delete_feed_data(link: str = Query(min_length=1)) -> dict[str, str]:
    with connect() as connection:
        cursor = connection.execute("DELETE FROM feed_data WHERE link = ?", (link,))
        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="Feed item not found")
        connection.commit()
    return {"status": "deleted"}
