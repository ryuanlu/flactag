#! /bin/sh

IFS='
'

# Functions


extract_field () {
	filelist=`cat TRACKS.txt`
	rm -f $FIELD.txt
	for f in $filelist
	do
		data=`metaflac --show-tag=$FIELD "$f"`
		if [ "$data" != "" ]; then
			metaflac --show-tag=$FIELD "$f" | cut -c`echo $FIELD= |wc -c`- >> $FIELD.txt
		else
			echo >> $FIELD.txt
		fi
	done
}

extract_all () {
	generate_sorted_tracklist
	FIELD=TITLE
	extract_field
	FIELD=ARTIST
	extract_field
	FIELD=LYRICIST
	extract_field
	FIELD=COMPOSER
	extract_field
	FIELD=ARRANGER
	extract_field
}

create_template () {

	find -name \*.flac|sort -V|cut -c3- > TRACKS.txt
	cp TRACKS.txt TITLE.txt
	touch ARTIST.txt
	touch LYRICIST.txt
	touch COMPOSER.txt
	touch ARRANGER.txt
	echo "ALBUM=" >> DISCINFO.txt
	echo "DATE=" >> DISCINFO.txt
	echo "LABEL=" >> DISCINFO.txt
	echo "CATALOGNUMBER=" >> DISCINFO.txt
	echo "DISCNUMBER=" >> DISCINFO.txt

}


arrange_to_disc () {
	line_position=0

	file_list=`find -name \*.flac`
	for f in $file_list
	do line_position=$(( line_position+1 ))
		discnumber=`awk "NR==$line_position" DISCNUMBER.txt`
		mv "$f" disc$discnumber/
	done
}


apply_field () {
	index=0

        filelist=`cat TRACKS.txt`

	for f in $filelist
	do index=$(( index+1 ))
		field_data=`awk "NR==$index" $FIELD.txt`
		metaflac --remove-tag=$FIELD "$f"

		if [ "$field_data" != "" ]; then
			metaflac --set-tag=$FIELD="$field_data" "$f"
		else
			echo Skip [$FIELD] for \"$f\"
		fi
	done
}

apply_disc_field () {
	
	field_name_size=`echo $FIELD=|wc -m`
	field_data=`grep -F "$FIELD=" DISCINFO.txt| cut -c$field_name_size-`
	echo "[$FIELD]=\"$field_data\""

	if [ "$field_data" != "" ]; then
		find -name \*.flac -exec metaflac --remove-tag=$FIELD {} \; -exec metaflac --set-tag=$FIELD="$field_data" {} \;
	fi
}


apply_tracknumber () {
        filelist=`cat TRACKS.txt`
	index=0
	total=`cat TRACKS.txt |wc -l`

        for f in $filelist
        do index=$(( index+1 ))
		metaflac --remove-tag=TRACKNUMBER "$f"
		metaflac --set-tag=TRACKNUMBER="$index" "$f"
		metaflac --remove-tag=TRACKTOTAL "$f"
		metaflac --set-tag=TRACKTOTAL="$total" "$f"
        done
}

generate_sorted_tracklist () {
	files=`find -name \*.flac`
	rm -f unsorted_list.txt
	for f in $files
	do
		echo `metaflac --show-tag=TRACKNUMBER $f`:$f >> unsorted_list.txt
	done

	sort -V unsorted_list.txt | sed 's/^TRACKNUMBER=.*:..//g' > TRACKS.txt
	rm -f unsorted_list.txt
}


full_pipeline () {
	#TITLE
	FIELD=TITLE
	apply_field

	#ARTIST
	FIELD=ARTIST
	apply_field

	#LYRICIST
	FIELD=LYRICIST
	apply_field

	#COMPOSER
	FIELD=COMPOSER
	apply_field

	#ARRANGER
	FIELD=ARRANGER
	apply_field

	#ALBUM
	FIELD=ALBUM
	apply_disc_field

	#DATE
	FIELD=DATE
	apply_disc_field

	#LABEL
	FIELD=LABEL
	apply_disc_field

	#LABELNO
	FIELD=CATALOGNUMBER
	apply_disc_field

	#DISCNUMBER
	FIELD=DISCNUMBER
	apply_disc_field

	#TRACKNUMBER
	apply_tracknumber

	metaflac --add-replay-gain *.flac
}



if [ "$#" -ne 1 ]; then
	echo Need command:
	echo 	new, apply, extract
	exit 1;
fi


if [ "$1" = "new" ]; then
	echo Creating templates ...
	create_template
	exit 0;
fi


if [ "$1" = "apply" ]; then
	echo Applying ...
	full_pipeline
	exit 0;
fi

if [ "$1" = "extract" ]; then
	echo Extracting ...
	generate_sorted_tracklist
	extract_all
	exit 0;
fi



exit 0




