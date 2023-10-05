get-content .env | foreach {
    $name, $value = $_.split('=')
    set-content env:\$name $value
}

az deployment sub create `
	--name $env:deploymentName `
	--location $env:location `
	--template-file main.bicep `
	--parameters param.json `
	-o json