#! /bin/bash -

# Twitter AutoStar

########################
# Constants

TEMP_DIRECTORY="/tmp/AutoStar"
if [ ! -d $TEMP_DIRECTORY ]
then
  mkdir $TEMP_DIRECTORY > /dev/null
fi

LOGFILE="$HOME/AutoStar.log"
echo >> $LOGFILE
date >> $LOGFILE

# Username
username="Twitter username"

# Password
password="Twitter Password"

# Temp file containing list of tweet guids
guidTempFile="$TEMP_DIRECTORY/GUID.$$.tmp"
rm -f guidTempFile
echo "Temp file containing the GUID of tweets: $guidTempFile"  >> $LOGFILE

# Temp file containing the just-starred tweet
starredTempFile="$TEMP_DIRECTORY/starred.$$.tmp"
rm -f starredTempFile
echo "Temp file containing the just-starred tweet: $starredTempFile" >> $LOGFILE

########################
# Read in list of users to star

staruser="User to Star goes here"

# File containing the last tweet to be starred
LastStarGuid="$HOME/$staruser"
touch $LastStarGuid

########################
# Get list of tweets

if [ ! -s $LastStarGuid ]
then
  curl -s -u $username:$password http://twitter.com/statuses/user_timeline/$staruser.rss | grep -oP \(?\<=/statuses/\)[0-9]*\(?=\</guid\>\) > $guidTempFile
  echo "Pulling in all tweets for $staruser" >> $LOGFILE
else
  since_id=`cat $LastStarGuid`
  curl -s -u $username:$password http://twitter.com/statuses/user_timeline/$staruser.rss?since_id=$since_id | grep -oP \(?\<=/statuses/\)[0-9]*\(?=\</guid\>\) > $guidTempFile
  echo "Pulling in tweets for $staruser since id $since_id" >> $LOGFILE
fi

echo "Outputing curl results to $guidTempFile" >> $LOGFILE

########################
# If tweets were starred, store latest number in text file
if [ -s $guidTempFile ]
then
  head -n 1 $guidTempFile > $LastStarGuid
fi

########################
# Star each tweet

for guid in `cat $guidTempFile`
do
  curl -sS -d "id=$guid" -u $username:$password http://twitter.com/favorites/create/$guid.xml > $starredTempFile
  text=`grep -oP "(?<=\<text\>)[\s\S]*(?=\</text\>)" $starredTempFile | perl -n -MHTML::Entities -e 'print decode_entities($_);'`
  if [ ! ${#text} = 0 ]
  then
    growlnotify -n AutoStar -m "$text"
  fi
done

########################
# Update Log Files
starCount=`wc -l $guidTempFile | grep -oP "\b[0-9]*\b"`
echo "Starred $starCount tweets" >> $LOGFILE


########################
# Cleanup temp files

# rm -f $guidTempFile
# rm -f $starredTempFile
