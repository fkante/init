user_exists=$(getent passwd $1)
if [ -z "$user_exists" ]
then
	echo "User $1 does not exist"
else
	echo "$1 entry: $user_exists"
	sudo userdel -rf $1
	echo "User $1 has been deleted"
fi
