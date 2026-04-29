function mv_comit --description 'Flatten *.zip files into the current directory'
    find . -name '*.zip' -print0 | xargs -0 -I {} mv {} .
end
