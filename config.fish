#eval (python3 -m virtualfish compat_aliases auto_activation global_requirements)

if not set -q __GIT_PROMPT_DIR
    set __GIT_PROMPT_DIR ~/bash-git-prompt
end

# Colors
# Reset
set ResetColor (set_color normal)       # Text Reset

# Regular Colors
set Red (set_color red)                 # Red
set Yellow (set_color yellow);          # Yellow
set Blue (set_color blue)               # Blue
set White (set_color white)
set Green (set_color green)
set WHOAMI (whoami)
set HOSTNAME (hostname)

# Bold
set BGreen (set_color -o green)         # Green

# High Intensty
set IBlack (set_color -o black)         # Black

# Bold High Intensty
set Magenta (set_color -o purple)       # Purple

# Default values for the appearance of the prompt. Configure at will.
set GIT_PROMPT_PREFIX "("
set GIT_PROMPT_SUFFIX ")"
set GIT_PROMPT_SEPARATOR "|"
set GIT_PROMPT_BRANCH "$Magenta"
set GIT_PROMPT_STAGED "$Red● "
set GIT_PROMPT_CONFLICTS "$Red✖ "
set GIT_PROMPT_CHANGED "$Blue✚ "
set GIT_PROMPT_REMOTE " "
set GIT_PROMPT_UNTRACKED "…"
set GIT_PROMPT_STASHED "⚑ "
set GIT_PROMPT_CLEAN "$Green✔"

function fish_prompt

    # Various variables you might want for your PS1 prompt instead
    set Time (date +%T)
    set PathShort (pwd|sed "s=$HOME=~=")

    set VIRTUAL_PROMPT ""
    if [ -n "$VIRTUAL_ENV" ]
        set VIRTUAL_BASENAME (basename $VIRTUAL_ENV)
        set VIRTUAL_PROMPT "$Yellow($VIRTUAL_BASENAME)$ResetColor"
    end

    set PROMPT_START "$VIRTUAL_PROMPT$White$Time$ResetColor:$WHOAMI@$HOSTNAME:"
    set PROMPT_END "$Yellow$PathShort$ResetColor"
    set PROMPT_SEP "\$"

    set -e __CURRENT_GIT_STATUS
    set gitstatus "$__GIT_PROMPT_DIR/gitstatus.py"

    set _GIT_STATUS (python $gitstatus)
    set __CURRENT_GIT_STATUS $_GIT_STATUS

    set __CURRENT_GIT_STATUS_PARAM_COUNT (count $__CURRENT_GIT_STATUS)

    if not test "0" -eq $__CURRENT_GIT_STATUS_PARAM_COUNT
        set GIT_BRANCH $__CURRENT_GIT_STATUS[1]
        set GIT_REMOTE "$__CURRENT_GIT_STATUS[2]"
        if contains "." "$GIT_REMOTE"
            set -e GIT_REMOTE
        end
        set GIT_STAGED $__CURRENT_GIT_STATUS[3]
        set GIT_CONFLICTS $__CURRENT_GIT_STATUS[4]
        set GIT_CHANGED $__CURRENT_GIT_STATUS[5]
        set GIT_UNTRACKED $__CURRENT_GIT_STATUS[6]
        set GIT_STASHED $__CURRENT_GIT_STATUS[7]
        set GIT_CLEAN $__CURRENT_GIT_STATUS[8]
    end

    if test -n "$__CURRENT_GIT_STATUS"
        set STATUS " $GIT_PROMPT_PREFIX$GIT_PROMPT_BRANCH$GIT_BRANCH$ResetColor"

        if set -q GIT_REMOTE
            set STATUS "$STATUS$GIT_PROMPT_REMOTE$GIT_REMOTE$ResetColor"
        end

        set STATUS "$STATUS$GIT_PROMPT_SEPARATOR"

        if [ $GIT_STAGED != "0" ]
            set STATUS "$STATUS$GIT_PROMPT_STAGED$GIT_STAGED$ResetColor"
        end

        if [ $GIT_CONFLICTS != "0" ]
            set STATUS "$STATUS$GIT_PROMPT_CONFLICTS$GIT_CONFLICTS$ResetColor"
        end

        if [ $GIT_CHANGED != "0" ]
            set STATUS "$STATUS$GIT_PROMPT_CHANGED$GIT_CHANGED$ResetColor"
        end

        if [ "$GIT_UNTRACKED" != "0" ]
            set STATUS "$STATUS$GIT_PROMPT_UNTRACKED$GIT_UNTRACKED$ResetColor"
        end
        
        if [ "$GIT_STASHED" != "0" ]
            set STATUS "$STATUS$GIT_PROMPT_STASHED$GIT_STASHED$ResetColor"
        end

        if [ "$GIT_CLEAN" = "1" ]
            set STATUS "$STATUS$GIT_PROMPT_CLEAN"
        end

        set STATUS "$STATUS$ResetColor$GIT_PROMPT_SUFFIX"

        set PS1 "$PROMPT_START$PROMPT_END$STATUS$PROMPT_SEP"
    else
        set PS1 "$PROMPT_START$PROMPT_END$PROMPT_SEP"
    end

    echo -e $PS1

end


setenv SSH_ENV $HOME/.ssh/environment

function test_identities
    ssh-add -l | grep "The agent has no identities" > /dev/null
    if [ $status -eq 0 ]
        ssh-add
        if [ $status -eq 2 ]
            start_agent
        end
    end
end


function fish_title
    if [ $_ = 'fish' ]
	echo (prompt_pwd)
    else
        echo $_
    end
end

function start_agent
	if [ -n "$SSH_AGENT_PID" ]
    		ps -ef | grep $SSH_AGENT_PID | grep ssh-agent > /dev/null
    		if [ $status -eq 0 ]
        		test_identities
    		end
	else
    		if [ -f $SSH_ENV ]
        		. $SSH_ENV > /dev/null
    		end
    	ps -ef | grep $SSH_AGENT_PID | grep -v grep | grep ssh-agent > /dev/null
    	if [ $status -eq 0 ]
        	test_identities
    	else
    		echo "Initializing new SSH agent ..."
	        ssh-agent -c | sed 's/^echo/#echo/' > $SSH_ENV
    		echo "succeeded"
		chmod 600 $SSH_ENV 
		. $SSH_ENV > /dev/null
    		ssh-add
	end
	end
end

start_agent

function __vf_cdp --description "Go to virtualenv project"
	if not set -q VIRTUAL_ENV
		echo "Activate a virtual environment first"
		return 1
	end
		
	set PROJECT_FILE $VIRTUAL_ENV/.project
	if test -e $PROJECT_FILE
		cd (cat $PROJECT_FILE)
	else
		echo "No .project file available for this env: $PROJECT_FILE"
	end
end


function __vf_setp --description "Set the current directory as project directory for the current env"
	if not set -q VIRTUAL_ENV
		echo "Activate a virtual environment first"
		return 1
	end

	pwd > $VIRTUAL_ENV/.project
end


function virtualfish_project_go --on-event virtualenv_did_activate
        set PROJECT_FILE $VIRTUAL_ENV/.project
        if test -e $PROJECT_FILE
                cd (cat $PROJECT_FILE)
        end
        if set -q VIRTUAL_ENV
            set -gx UV_PROJECT_ENVIRONMENT $VIRTUAL_ENV
        end
end

rvm default
set -g -x PATH $PATH ~/bin ~/.local/bin ~/.rbenv/bin: ~/.rbenv/plugins/ruby-build/bin:
pyenv init - | source
rbenv init - | source

