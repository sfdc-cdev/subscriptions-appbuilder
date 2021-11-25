echo "Variables"
# dhALIAS="dh100" // WORKS
dhALIAS="dh100"
soALIAS="soAppBuilder"
echo "DH: ${dhALIAS}"
echo "SO: ${soALIAS}"
source "./orgInit.sh"
sfdx config:set defaultusername="${soALIAS}"
exit 0