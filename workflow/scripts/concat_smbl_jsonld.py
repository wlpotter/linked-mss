import json

ontology_file = snakemake.input[1]

with open(snakemake.input[0]) as template_file:
    results = json.load(template_file)

with open(snakemake.input[1]) as ontology_file:
    ontology = json.load(ontology_file)

graph = []
for i in range(2, len(snakemake.input) - 1):
    with open(snakemake.input[i]) as rec:
        try:
            graph.append(json.load(rec))
        except Exception: 
            print(snakemake.input[i])
            print(Exception)

# append the ontology data to the resulting graph
for node in ontology:
    graph.append(node)

# add the dataset and ontology as the @graph JSON-LD parameter
results["@graph"] = graph

# save to the output file
with open("results/smbl.json", 'w') as output:
    json.dump(results, output, indent=2)