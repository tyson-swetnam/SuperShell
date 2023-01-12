sessionid="Unknown Cyverse ID"
homeLocation='DirectoryPath/*'
for FILEPATHS in $homeLocation; 
do 
    ITEM=$(basename "$FILEPATHS")
    if [[ "$ITEM" != "shared" ]];
    then
        sessionid="$ITEM" 
    fi
done
echo $sessionid