<?php

require_once 'Net/Socket/Tiarra.php';

try
{
    $tiarra = new Net_Socket_Tiarra('tyoro');

    $tiarra->message("$argv[1]", "$argv[2]");

} catch (Net_Socket_Tiarra_Exception $e) {
    echo $e->getMessage();
}
