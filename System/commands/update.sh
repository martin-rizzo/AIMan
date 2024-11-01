# **Update Subcommand**
#
# The `update` subcommand allows you to manage the version of your AI project.
# You can use it to update your project to a specific version, the latest
# available version, reinstall the project from scratch, or even update the
# Python virtual environment.
#
# Update project 
#   > aiman update <project-name>              # Updates the project to its stable version saved in the database.
#   > aiman update <project-name> --latest     # Updates the project to the latest available version (which may be unstable).
#                                              # Please note that using this option may result in unexpected behavior or bugs.
# Reinstall Project
#   > aiman update <project-name> --reinstall  # Completely removes and re-installs the project from scratch,
#                                              # updating it to its stable version.
#                                              # This option is useful when you want to start fresh with a clean installation of the latest stable version.
#
# Update Virtual Environment
#  > aiman update <project-name> --vev         # Updates the Python virtual environment by deleting it and recreating it from scratch.
#                                              # This ensures that your project dependencies are up-to-date and consistent with the latest version of the project.
#
