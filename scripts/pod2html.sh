#!/bin/bash

DIR1=Perl-modules/html
DIR2=X500/DN
FILE=$DIR1/$DIR2/Marpa.html

pod2html.pl -i lib/X500/DN/Marpa.pm -o $DR/$FILE

mkdir -p ~/savage.net.au/$DIR1/$DIR2

cp $DR/$FILE ~/savage.net.au/$FILE
