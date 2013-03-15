#!/bin/bash

# Gitover: Send Git commit notifications to Pushover.
# by Tim @scy Weber
# https://github.com/scy/gitover
# Licensed under the terms of the WTFPL, version 2.

MY_DIR="$(dirname "$0")"

# Where Gitover stores its repositories. You can override this in the config.
REPO_DIR="$MY_DIR/repos"

# Parseable "git log" output.
overlog() {
	# We use vars from the global scope here, which is ugly, but works.
	git log --pretty=format:%H:%at:%an:%s "$old_head..$new_head"
	echo # Required for correct line count.
}

# Load the config file.
. "$MY_DIR/gitover.conf.bash"

# Check whether the repo dir exists.
if [ ! -d "$REPO_DIR" ]; then
	echo "$REPO_DIR is not a directory" >&2
	exit 1
fi

# Iterate over the repositories.
for repodef in $REPOS; do
	# Parse $repodef, which is an equals-separated list of name and URL.
	reponame="$(echo "$repodef" | cut -d = -f 1)"
	repodir="$REPO_DIR/$reponame"
	repourl="$(echo "$repodef" | cut -d = -f 2-)"
	# The users to be notified are defined in variable variables. For example,
	# if your project is named "foo", then the users are in $USERS_foo.
	usersvar="USERS_$reponame"
	users="${!usersvar}"
	# Same thing for the web interface definition.
	webvar="WEB_$reponame"
	webdef="${!webvar}"
	# Parse $webdef, which is a pipe-separated list of name, basic URL (not
	# specifying a certain commit) and commit URL (showing a specific commit).
	webname="$(echo "$webdef" | cut -d '|' -f 1)"
	webbase="$(echo "$webdef" | cut -d '|' -f 2)"
	webcommit="$(echo "$webdef" | cut -d '|' -f 3)"
	# If the repo does not exist, clone it and be done.
	if [ ! -d "$repodir" ]; then
		echo "$repodir does not exist, cloning ..."
		git clone "$repourl" "$repodir"
	else
		echo "Checking $reponame ..."
		cd "$repodir" # We'll "cd -" later.
		# Keep the old HEAD.
		old_head="$(git rev-parse HEAD)"
		# Pull updates.
		git pull >/dev/null
		# Get the new HEAD.
		new_head="$(git rev-parse HEAD)"
		if [ "$old_head" != "$new_head" ]; then
			# The HEADs differ, do a notification.
			# First, check how many commits were made between the HEADs.
			commit_count="$(overlog | wc -l)"
			# Singular or plural?
			commit_word="commit"
			[ "$commit_count" -ne 1 ] && commit_word="${commit_word}s"
			# Show status message.
			echo "  HEAD has changed from $old_head to $new_head ($commit_count $commit_word)"
			if [ "$commit_count" -eq 1 ]; then
				# Retrieve commit hash, date, author and subject (as message body).
				chash="$(overlog | cut -d : -f 1)"
				cdate="$(overlog | cut -d : -f 2)"
				author="$(overlog | cut -d : -f 3)"
				message="$(overlog | cut -d : -f 4-)"
				# Create a title for the notification.
				title="$reponame $commit_word by $author"
				# Create a web link by replacing %H with the commit hash.
				weblink="$(echo "$webcommit" | sed -e "s/%H/$chash/g")"
			else
				# Retrieve newest commit date; we don't care about author (since
				# it's possibly more than one) or hash (since we don't link).
				cdate="$(overlog | head -n 1 | cut -d : -f 2)"
				# Create a title containing the number of commits.
				title="$commit_count $reponame $commit_word"
				# Build the message by concatenating the commit subjects.
				message="$(overlog | cut -d : -f 4- | sed -e 's/$/; /' | tr -d '\n' | sed -e 's/; $//')"
				# Simply link to the general web interface URL.
				weblink="$webbase"
			fi
			# Iterate over each user that is to be notified.
			for userdef in $users; do
				# Parse $userdef, which is an equals-separated list of name and
				# Pushover "user key".
				username="$(echo "$userdef" | cut -d = -f 1)"
				userkey="$(echo "$userdef" | cut -d = -f 2)"
				# Notify the user.
				echo "    Notifying $username ..."
				if ! curl -fs --form-string "token=$APP_TOKEN" \
				              --form-string "user=$userkey" \
				              --form-string "title=$title" \
				              --form-string "message=$message" \
				              --form-string "url=$weblink" \
				              --form-string "url_title=View on $webname" \
				              --form-string "timestamp=$cdate" \
				              https://api.pushover.net/1/messages.json >/dev/null; then
					# If notifying failed for some reason, simply output
					# "failed" and don't care.
					echo '      failed!'
				fi
			done
		fi
		# Go back to the directory we came from.
		cd - >/dev/null
	fi
done
