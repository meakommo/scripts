$ports=2
$port=1
$ip="127.0.0.1";
while ($port -lt $ports) {try{$socket=New-object System.Net.Sockets.TCPClient($ip,$port);
 }catch{};
 if ($NULL -eq $socket) {Write-Output $ip":"$port" - Closed"; $port++}
 else {Write-Output $ip":"$port"- Open";$socket=$NULL;$port++}
}
