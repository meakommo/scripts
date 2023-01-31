try {
    node --version
    $vm2 = ls c:\ *vm2* -Recurse -Directory
    write-output $vm2
}
catch {
    {"Node is note installed"}
}
