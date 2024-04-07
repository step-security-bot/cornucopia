#!/bin/bash -eu
# How to test locally:
# cd ../
# git clone https://github.com/google/oss-fuzz
# cd ../oss-fuzz
# export PATH_TO_PROJECT=/home/sydseter/shared/cornucopia
# python infra/helper.py build_fuzzers --external $PATH_TO_PROJECT --sanitizer address
# python infra/helper.py build_image --external $PATH_TO_PROJECT
# python infra/helper.py check_build --external $PATH_TO_PROJECT --sanitizer address

# build project
update-alternatives --set python3 /usr/bin/python3.10
#pip install nuitka
python3 -m pip install -r requirements.txt --require-hashes
python3 -m pip  install -r install_cornucopia_deps.txt --require-hashes --no-deps
$SRC=$(pwd)
echo "What is here?"
ls
pwd
#for debugging
#exec "$SHELL"
# Build fuzzers into $OUT. These could be detected in other ways.
for fuzzer in $(find "$SRC/tests/scripts" -name '*_fuzzer.py'); do
  fuzzer_basename=$(basename -s .py $fuzzer)
  fuzzer_package=${fuzzer_basename}.pkg

  #python3 -m nuitka3 --output-dir=$OUT --onefile --output-filename=$fuzzer_package $fuzzer
  python3 -m PyInstaller --distpath $SRC --onefile --name $fuzzer_package $fuzzer

  echo "#!/bin/sh
# LLVMFuzzerTestOneInput for fuzzer detection.
echo "fuzzing now, this is what is here"
ls
pwd
this_dir=\$(dirname \"\$0\")
ASAN_OPTIONS=\$ASAN_OPTIONS:symbolize=1:external_symbolizer_path=\$this_dir/llvm-symbolizer:detect_leaks=0 \
\$this_dir/tests/scripts/$fuzzer_package \$@" > $SRC/$fuzzer_basename
  chmod +x $SRC/$fuzzer_basename
done

# build fuzzers
# e.g.
# $CXX $CXXFLAGS -std=c++11 -Iinclude \
#     /path/to/name_of_fuzzer.cc -o $OUT/name_of_fuzzer \
#     $LIB_FUZZING_ENGINE /path/to/library.a
