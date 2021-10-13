#!/bin/bash

sudo cat <<EOF > /var/www/html/index.html 
<HTML>
    <body>
        <h1>UI App</h1> 
        <p>$(hostname -f)</p>
    </body>
</HTML>
EOF