# gitover - send Pushover notifications for new Git commits

## What it does
When called, it will pull the Git repositories it's configured to watch. If there are any changes, the [Pushover][] users configured for that repository will receive a notification about that commit.

## What you need
* A Unix server with bash and Git to run it on.
* A [Pushover][] account for everyone who should receive notifications.

## How to install it
Clone this repository. Be done.

## How to configure it
Copy `gitover.conf.bash.example` to `gitover.conf.bash` and modify it to your needs. The file is documented inline.

## License?
The [WTFPL][], version 2.

## FAQ

### This looks like it's made for cron usage instead of in a commit hook. Why?
That's right. I wanted it to work in environments where you're possibly not able to install a commit hook. But you can of course call it from a commit hook instead of cron, if you want to. If anybody wants to introduce a mechanism to only check a single repository, I'm open for pull requests.

[Pushover]: https://pushover.net/
[WTFPL]:    http://www.wtfpl.net/about/
