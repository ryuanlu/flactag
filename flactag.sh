#! /bin/sh

IFS='
	'

# Functions


extract_field () {
	filelist=`cat TRACKS.txt`
	rm -f $1.txt
	for f in $filelist
	do
		data=`metaflac --show-tag=$1 "$f"`
		if [ "$data" != "" ]; then
			metaflac --show-tag=$1 "$f" | cut -c`echo $1= |wc -c`- >> $1.txt
		else
			echo >> $1.txt
		fi
	done
}

extract_all () {
	generate_sorted_tracklist

	FIELDS="TITLE	ARTIST	LYRICIST	COMPOSER	ARRANGER	COMMENT"

	for FIELD in $FIELDS
	do
		extract_field $FIELD
	done
}

create_template () {

	find -name \*.flac|sort -V|cut -c3- > TRACKS.txt
	cp TRACKS.txt TITLE.txt
	touch ARTIST.txt
	touch LYRICIST.txt
	touch COMPOSER.txt
	touch ARRANGER.txt
	touch COMMENT.txt

	rm -f DISCINFO.txt
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
		field_data=`awk "NR==$index" $1.txt`
		metaflac --remove-tag=$1 "$f"

		if [ "$field_data" != "" ]; then
			metaflac --set-tag=$1="$field_data" "$f"
		else
			echo Skip [$1] for \"$f\"
		fi
	done
}

apply_disc_field () {
	
	field_name_size=`echo $1=|wc -m`
	field_data=`grep -F "$1=" DISCINFO.txt| cut -c$field_name_size-`
	echo "[$1]=\"$field_data\""

	if [ "$field_data" != "" ]; then
		find -name \*.flac -exec metaflac --remove-tag=$1 {} \; -exec metaflac --set-tag=$1="$field_data" {} \;
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


apply_lyrics () {
        index=0

        filelist=`cat TRACKS.txt`

        for f in $filelist
        do index=$(( index+1 ))
                title=`awk "NR==$index" TITLE.txt`
                metaflac --remove-tag=LYRICS "$f"
		lyrics=`cat "$title".lyrics 2>/dev/null`

                if [ "$lyrics" != "" ]; then
                        metaflac --set-tag=LYRICS="$lyrics" "$f"
                        echo Apply [LYRICS] for \"$f\"
                fi
        done
}

rename_by_title () {
        index=0

        filelist=`cat TRACKS.txt`

        for f in $filelist
        do index=$(( index+1 ))
                title=`awk "NR==$index" TITLE.txt`

                if [ "$title" != "" ]; then
			mv "$f" "$title".flac
                fi
        done

}


generate_sorted_tracklist () {
	files=`find -name \*.flac`
	rm -f unsorted_list.txt
	for f in $files
	do
		echo `metaflac --show-tag=TRACKNUMBER "$f"`:"$f" >> unsorted_list.txt
	done

	sort -V unsorted_list.txt | sed 's/^TRACKNUMBER=.*:..//g' > TRACKS.txt
	rm -f unsorted_list.txt
}


full_pipeline () {

	metaflac --remove-all *.flac

	FIELDS="TITLE	ARTIST	LYRICIST	COMPOSER	ARRANGER	COMMENT"
	for FIELD in $FIELDS
	do
		apply_field $FIELD
	done

	FIELDS="ALBUM	DATE	LABEL	CATALOGNUMBER	DISCNUMBER"
	for FIELD in $FIELDS
	do
		apply_disc_field $FIELD
	done

	#TRACKNUMBER
	apply_tracknumber

	apply_lyrics

	metaflac --add-replay-gain *.flac
	metaflac --add-seekpoint=10s *.flac
}



if [ "$#" -ne 1 ]; then
	echo "Need command:"
	echo "new, apply, extract, rename"
	exit 1;
fi


if [ "$1" = "new" ]; then
	echo "Creating templates ..."
	create_template
	exit 0;
fi


if [ "$1" = "apply" ]; then
	echo "Applying ..."
	full_pipeline
	exit 0;
fi

if [ "$1" = "extract" ]; then
	echo "Extracting ..."
	generate_sorted_tracklist
	extract_all
	exit 0;
fi

if [ "$1" = "rename" ]; then
	echo "Renaming ..."
	rename_by_title
	exit 0;
fi


exit 0




