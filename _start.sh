start=`date +%s`
vagrant up
vagrant plugin install vagrant-hostmanager
vagrant hostmanager
end=`date +%s`

runtime=$((end-start))
echo Time taken to complete: $runtime in seconds
