cd "../../../etc/nginx/sites-available/"

if [[ $1 == "off" ]]
then
	sed -i 's/autoindex on/autoindex off/g' "default"
	nginx -s reload
elif [[ $1 == "on" ]]
then
	sed -i 's/autoindex off/autoindex on/g' "default"
	nginx -s reload
else
	echo "no arguments given, please choose: [ on / off ]"
fi