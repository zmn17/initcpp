#!/bin/bash

# progress bar
print_progress_bar(){
	local progress=$1
	local label=$2
	local width=30

	local filled=$((progress * width / 100))
	local empty=$((width - filled))

	local bar=""
	for ((i = 0; i < filled; i++)); do bar+="#"; done
	for ((i = 0; i < emtpy; i++)); do bar+="."; done

	echo -ne "\rGenerating '$label' file [${bar}] ${progress}%" 
}

#1. create a project folder
#1a. ask user for project name
read -p "Project name: " name

# check if folder exists
if [[ -d $name ]]; then
	echo "\033[1;31mERROR:\033[0m folder '$name' already exits."
	exit 1
fi

# check if this is an OpenGL app
read -p "Add as OpenGL application? (y/N): " isopengl

#1b. create directories for the project
mkdir "$name" 
cd "$name"|| exit 1

mkdir src include

# create emtpy main.cpp
touch src/main.cpp

# if its opengl app
if [[ "$isopengl" == "Y" || "$isopengl" == 'y' ]]; then
	# create directories
	mkdir external shaders textures bin

	# symlink external libraries
	ln -s /home/zee/dev/opengl-lib/build/libopengl_utils.a external/
	ln -s /home/zee/dev/opengl-lib/include/ external/include

	# add default makefile
	cat > Makefile << 'EOF'
	
# compiler and flags
CXX = g++
CXXFLAGS = -g -I/usr/include -I/usr/include/GLFW -Iexternal/include
LDFLAGS = -L/usr/lib/ -lGLEW -lglfw -lGL -lm -Lexternal -lopengl_utils

# directories
SRC_DIR = src
BIN_DIR = bin
INCLUDE_DIR = include

# source and object files
SRCS = $(SRC_DIR)/main.cpp 

OBJS = $(patsubst %.cpp,$(BIN_DIR)/%.o,$(notdir $(SRCS)))

# executable name
EXEC = main

# default target
all: $(EXEC)

# linking
$(EXEC): $(OBJS)
	$(CXX) $(CXXFLAGS) $(OBJS) -o $@ $(LDFLAGS)

# pattern rule for compiling .cpp to .o
$(BIN_DIR)/%.o: $(SRC_DIR)/%.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

# run the executable
run: all
	./$(EXEC)

# clean build artifacts
clean:
	rm -f $(BIN_DIR)/*.o $(EXEC)
EOF

	# create compile_commands.json file
	if command -v bear &> /dev/null; then
		bear -- make &> /dev/null & # run in the background
		pid=$!

		# stimulate progress bar 
		for i in {0..100..10}; do
			print_progress_bar "$i" "compile_commands.json"
			sleep 0.2
		done

		wait $pid
		echo -e "\n\033[1;32mDone.\033[0m"
	else
		echo "bear command not found."

	fi

else
	# create emtpy Makefile
	touch Makefile

fi

# initaliza git add .gitignore
read -p "Do you want to add git to '$name'? (y/N): " addgit
if [[ "$addgit" == "y" || "$addgit" == "Y" ]]; then
    git init .
fi

# add .gitignore
default_gitignore="# Build artifacts
*.o
*.obj
*.lo
*.la
*.al
*.libs
*.a
*.so
*.so.*
*.dylib
*.dll
*.exe
*.out
*.app

# Dependency files
*.d

# CMake files
CMakeFiles/
CMakeCache.txt
cmake_install.cmake
Makefile

# Auto-generated files
*.log
*.tmp

# Editor/IDE config
*.swp
*.swo
*~
.vscode/
.idea/
compile_commands.json

# Static analysis and test artifacts
*.gcno
*.gcda
*.gcov
*.profraw
*.profdata

# Project-specific folders
build/
bin/
obj/
dist/
debug/
release/

# OS-specific
.DS_Store
Thumbs.db

# Others
*.cache
"
read -p "Add .gitignore? (y/n): " addgitignore
if [[ "$addgitignore" == 'Y' || "$addgitignore" == 'y' ]]; then
	touch .gitignore
	echo "$default_gitignore" > .gitignore
fi

# add readme.md file
read -p "Add README.md (y/n): " addreadme
if [[ $addreadme == 'Y' || $readme == 'y' ]]; then
	touch README.md
fi

echo -e "'$name' \033[1;32mwas successfully created.\033[0m"
