sessionid="Unknown Cyverse ID"
homeLocation='/home/jovyan/data-store/user'
if [[ -d "$homeLocation" ]];
then
    toCheck="${homeLocation}/*"
    for FILEPATHS in $toCheck; 
    do 
        ITEM=$(basename "$FILEPATHS")
        if [[ "$ITEM" != "shared" ]];
        then
            sessionid="$ITEM" 
        fi
    done
fi
echo $sessionid