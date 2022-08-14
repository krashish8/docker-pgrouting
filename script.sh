postgresVer=("11" "12" "13" "14")
postgisVer=("3.2")
pgroutingVer=("3.0" "3.1" "3.2" "3.3" "master" "develop")

include=("10-2.5-master" "10-2.5-develop" "11-2.5-master" "11-2.5-develop")
exclude=("11-3.2-master" "11-3.2-develop")

for postgres in ${postgresVer[@]}; do
    for postgis in ${postgisVer[@]}; do
        for pgrouting in ${pgroutingVer[@]}; do
            folder="$postgres-$postgis-$pgrouting"
            if [[ ! " ${exclude[*]} " =~ " ${folder} " ]]; then
                mkdir "$folder"
                touch "$folder/Dockerfile"
            fi
        done
    done
done

for folder in ${include[@]}; do
    mkdir "$folder"
    touch "$folder/Dockerfile"
done
