#!/bin/bash

printf '\e[4m\e[1;31m'"Replacing script\n"'\e[0m'
read -p "Please enter your parameter to be replace: " var1
read -p "Please enter your new parameter: " var2

for f in $(grep -r "$var1" . | cut -d ":" -f1 | egrep  "(\.h)|(\.c)")
	do echo "$f"
done

read -p "Sure ? yes or no: " var3

if [[ $var3 = "yes" || $var3 = "y" ]]; then
mkdir old
	for f in $(grep -r "$var1" . | cut -d ":" -f1 | egrep  "(\.h)|(\.c)")
		do sed -i '.bak' "s~$var1~$var2~g" $f
		printf -- '\e[1;32m'"new/"$f" created\n"'\e[0m';
	done
	for j in $(find . | egrep  "(\.h.bak)|(\.c.bak)")
		do	mv -f $j old
	done
	printf -- '\n';
	printf -- '\e[1;32m'"DONE!\n"'\e[0m';
else
	printf -- '\e[1;31m'"ABORTED\n"'\e[0m';
fi
