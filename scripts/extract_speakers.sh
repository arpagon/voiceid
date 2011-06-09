#!/bin/bash 

processors=$(grep -c ^processor /proc/cpuinfo)
videofile=$1

max_score=0
best_speaker_name="unknown"

./video2trim.sh "$videofile"

function speakerdb_vs_samples (){

		speaker_db=$1
		speaker_samples=$2		

		original_speak=$(cat db/$speaker_db/speakers.txt)
		similar=0
		different=0
		reportname=${speaker_v}_vs_${speaker_db}.txt	
		reportcodename=${speaker_v}_vs_${speaker_db}_small_report.txt
		echo "${speaker_v}_vs_${speaker_db}" > $reportname
		for sample in $speaker_samples
		do 
			seconds=$( soxi -s $name/$speaker_v/$sample )
			sec=$( soxi -D $name/$speaker_v/$sample )
			printf "speaker_v %s | sample %13s | speaker_db %10s %2F "  "$speaker_v"  $sample $speaker_db $sec   >> $reportname
			num_speak=$(  ./test_2_speakers.sh db/$speaker_db/*wav $name/$speaker_v/$sample 2>&1 |grep -c ";;" )
			if (( $num_speak <= $original_speak  ))
			then 
				similar=$(( $similar + $seconds   ))	
				printf "*\n" >> $reportname
			else
				different=$(( $different + $seconds ))	
				printf "\n" >> $reportname
			fi

		done
		total=$(( $similar + $different ))
		echo "statistics for speaker $speaker_v" >> $reportname
		echo similarity = $((  (100 *  $similar  ) / $total  )) %  >> $reportname
		cat $reportname
	
                current_score=$((  (100 *  $similar  ) / $total  ))
		if (( $max_score <= $current_score )) 	
		then
			max_score=$current_score
			best_speaker_name=${speaker_db}	
		fi	
		echo -e "\t${speaker_db} \t $current_score%" >>$totalreport
}

directory=$(dirname "$1")
show=`basename "$1"`
_show=$( echo "$show" | sed -e 's/ /_/g' | sed -e 's/\\//g' ) 
#mv -n "$directory"/"$show" "$directory"/"$_show"
totalreport=${_show}_SPEAKERS.txt
show="$directory"/$_show
#echo $show
#exit 1

if [ -f "$show" ] ; then
    # name without extension
    name=${show%\.*}
 #   echo ${name} 
fi ;
echo "$name" >$totalreport

speakers_in_video=$(ls $name)
echo "speakers in video = " $speakers_in_video


speakers_in_db=$(ls db)
echo "speakers in db = " $speakers_in_db



for speaker_v in $speakers_in_video
do

	best_speaker_name="unknown"
	max_score=0
	speaker_samples=$( ls $name/$speaker_v )

	echo "$speaker_v:" >> $totalreport

	for speaker_db in $speakers_in_db  
	do
		speakerdb_vs_samples "$speaker_db"  "$speaker_samples"
	done
	echo -e "\tbest speaker: \t$best_speaker_name" >>$totalreport
	echo -e "\t$speaker_v  \t$best_speaker_name" >>$reportcodename
	printf "*********\n"
	
done

./srt2subnames.sh ${name}.srt ${video}_SPEAKERS.txt 
cat $totalreport


