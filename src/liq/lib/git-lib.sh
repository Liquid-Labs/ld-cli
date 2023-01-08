lib-git-determine-default-branch() {
	local DEFAULT_BRANCH
	DEFAULT_BRANCH=$({ git symbolic-ref refs/remotes/upstream/HEAD 2> /dev/null || echo ''; } \
		| sed 's@^refs/remotes/upstream/@@' || '')
	if [[ -z "${DEFAULT_BRANCH}" ]]; then
		DEFAULT_BRANCH=$(git remote show upstream | sed -n '/HEAD branch/s/.*: //p')
	fi
	if [[ -z "${DEFAULT_BRANCH}" ]]; then
		echoerrandexit "Could not determine default branch."
	fi

	echo "${DEFAULT_BRANCH}"
}
