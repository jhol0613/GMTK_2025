# Git for Artists

**Git** is a version control system that is widely used for developing
software. It is focused on making incremental changes, unlike file sharing
services and cloud providers. Git is aimed to make our collaboration easier, as
well as lower the risk of losing important data. It's basically a time machine
for your projects!

This tutorial should cover most of the things that you would need to do while
working on the game. I tried to keep it simple and short, but if anthing is
unclear, please let me know. This tutorial is done for GitHub Desktop, which is
in my opinion the most intuitive ways to work with Git.

## Installation and authentication

[Download GitHub Desktop](https://desktop.github.com/download/) for your
system. Follow the instructions, this should be relatively effortless.

To authenticate, click on "File -> Options..."

![Select "File -> Options..." in the context menu](/tutorial/auth_option.png)

Then click "Sign in". Log in with your browser, this should be your result.

![Sign in form](/tutorials/auth_signing.png)

If you don't want to have your email be public through GitHub repositories,
choose "Git" and select the "noreply" option instead of your email.

![Git options panel, remove email from public view](/tutorials/auth_email.png)

## Cloning the repository

Now, to downloading the project. Select "File -> Clone repository..." in the
context menu:

![Select "File -> Clone repository..."](/tutorials/cloning.png)

If you are logged in and added to the repository, it should appear in the pop
up menu. In the "Local path" prompt, select the folder where you would like to
put all our files. You can clone the repository multiple times to different
local paths, if you want to have multiple Godot projects open at the same time.

![Select a repository prompt](/tutorials/cloning_repository.png)

## UI

This is how your interface should look after cloning the repository. Notice the
repository name, branch and "Fetch origin" buttons. They should say the same
things as on the screenshot.

![Regular UI of GitHub Desktop](/tutorials/ui.png)

The left panel lists the files that were changed, created or deleted. You can
switch to the History tab to show previous commits and their diffs.

The right panel will show you how exactly the file was changed, line by line.

This is how the "History" tab looks like.

![History tab view](/tutorials/ui_history.png)

You can right-click on some commits to see more options: "Checkout commit"
means rewinding your local project to that commit. "Revert commit" means
undoing the change you (or someone else) made in that commit. This will create
another commit that "reverts" the selected commit, it doesn't delete the
commit, but don't worry about that. This feature is particularly useful for
fixing a broken build of the game.

## Making commits

Now, you can make some changes to the project. This is what the UI should look
like after a few edits.

![Commit UI](/tutorials/ui_changed.png)

Notice that only one file on the left is selected, only
the selected files are being committed to the repository. When you are done
with your commit, select the files you want to commit, write a short commit
message and hit "Commit".

This is what you should get right after you made a commit. The changes have
disappeared from your left panel, but just the ones you selected earlier. The
"Fetch origin" button is now "Push origin" button, meaning you have some local
commits that you have not yet "pushed" to the GitHub repository. Until you
"push" something, it stays on your machine, so you can do whatever you want
with it.

![UI after making a commit](/tutorials/commit.png)

If you are satisfied with your changes, hit push. Then, your commit should
appear in the GitHub repo. Congrats, you just made your first push in the
repository!

## Updating your workspace

Before committing your changes, try to first update your repository
information, or "Fetch". If there are commits from others in the repository,
the button will say "Pull". Until you "pull" the changes, they will not appear
in your project folder, so to keep up to date, fetch and pull every once in a
while.

![Fetch dropdown menu](/tutorials/fetch.png)

If you have already made a commit to your local repository before fetching a
new commit from GitHub, you may encounter a merge conflict. It should be
resolved automatically as each of you will have your own folders, but in case
it happens, call John or me for help.

## Stashing and resetting

Sometimes, you will need to manipulate your changes without making a commit.
Maybe you were experimenting and your project is now broken, or you were
playing the game and some project files were changed, but you don't want to
commit those changes. Simply select the files you want to discard, hit the
right mouse button and click the "discard" button. This will reset selected
files to the latest commit.

![Stash and reset options menu](/tutorials/stash_reset.png)

Sometimes, you don't want to discard the changes, but you need a clean
workspace. For example, if you are pulling some changes, the app might tell you
to "stash" your current changes. Stash keeps some changes hidden from your
folder, so that you can return to them later. The stash is local, so you can
keep whatever you want there.

![Stashed changes view](/tutorials/stash.png)

To apply the stashed changes back to the repository, hit the "Restore" button.

## I changed the project folder. What do I do?

Open your changes panel on the left. Find all files that start with
"godot_project/". Select them with shift-click, selecting just the checkboxes
won't work.

![Discard changes on selected files](/tutorials/resetting.png)

Click with right mouse button, select "Discard x files...". Confirm, and now
you have a clean Godot project in your folder.

