# dmc-performance

try:
	if not gSTARTED: print( gSTARTED )
except:
	MODULE = "dmc-performance"
	include: "../DMC-Corona-Library/snakemake/Snakefile"

module_config = {
	"name": "dmc-performance",
	"module": {
		"dir": "dmc_corona",
		"files": [
			"dmc_performance.lua"
		],
		"requires": [
			"dmc-corona-boot",
		]
	},
	"tests": {
		"files": [],
		"requires": []
	}
}

register( "dmc-performance", module_config )

