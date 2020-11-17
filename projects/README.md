# Kiss Projects

The projects in these folders use kiss in various environments. Some of them might be useful on their own. They are in this repository so they can be tested automatically along with the Kiss compiler.

Each folder's test.sh file will be run automatically by Travis. Project test scripts report failures simply via non-zero exit codes, or if the project throws an exception while running.

Projects can also supply a manual-test.sh file which will run when you run test-all.sh in the repository root. Manual tests can use GUIs, which makes them very useful, but it is harder to guarantee they are run regularly.