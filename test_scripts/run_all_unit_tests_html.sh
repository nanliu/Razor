# Runs all unit tests with HTML output to WEBPATH specified
# You must change webpath to match your

echo "RAZOR_RSPEC_WEBPATH is: $RAZOR_RSPEC_WEBPATH"
echo "RAZOR HOME is: $RAZOR_HOME"
cd $RAZOR_HOME

rspec -c -f h > $RAZOR_RSPEC_WEBPATH/razor_tests.html
