"use strict";

(() => {
  const modelPath = "https://ar.sukolsak.com";

  const database = [["acetamid","Acetamid",0],["acetate","Acetate",0],["acetic_acid","Acetic acid",0],["acetone","Acetone",0],["acetonitrile","Acetonitrile",0],["acetophenone","Acetophenone",0],["acetylen","Acetylen",0],["acrolein","Acrolein",0],["acrylonitrile","Acrylonitrile",0],["adenine","Adenine",0],["adipic_acid","Adipic acid",0],["adrenaline","Adrenaline",0],["alanine","Alanine",0],["allose","Allose",0],["altrose","Altrose",0],["aminopyridine","Aminopyridine",0],["ammonia","Ammonia",0],["anilin","Anilin",0],["anthracene","Anthracene",0],["arabinose","Arabinose",0],["arginine","Arginine",0],["ascorbate","Ascorbate",0],["asparagine","Asparagine",0],["aspartic_acid","Aspartic acid",0],["aspirin","Aspirin",0],["atropine","Atropine",0],["azobenzene","Azobenzene",0],["azulene","Azulene",0],["bodipy","BODIPY",0],["benzaldehyde","Benzaldehyde",0],["benzamide","Benzamide",0],["benzene","Benzene",0],["benzenecarbothioamide","Benzenecarbothioamide",0],["benzimidazole","Benzimidazole",0],["benzo[a]pyrene","Benzo[a]pyrene",0],["benzo[c]fluorene","Benzo[c]fluorene",0],["benzo[ghi]perylene","Benzo[ghi]perylene",0],["benzoate","Benzoate",0],["benzofuran","Benzofuran",0],["benzoic_acid","Benzoic acid",0],["benzonitrile","Benzonitrile",0],["benzophenone","Benzophenone",0],["benzylhydrazine","Benzylhydrazine",0],["biphenyl","Biphenyl",0],["bromobenzene","Bromobenzene",0],["bromoethane","Bromoethane",0],["bromotrimethylsilane","Bromotrimethylsilane",0],["buckyball","Buckminsterfullerene",0],["butadiene","Butadiene",0],["butanol","Butanol",0],["butene","Butene",0],["butyl_alcohol","Butyl alcohol",0],["cadaverine","Cadaverine",0],["caffeic_acid","Caffeic acid",0],["caffeine","Caffeine",0],["camphora","Camphora",0],["cannabinol","Cannabinol",0],["carbimazole","Carbimazole",0],["carbitol","Carbitol",0],["carbon_dioxide","Carbon dioxide",0],["carbon_monoxide","Carbon monoxide",0],["carbonate","Carbonate",0],["carbonic_acid","Carbonic acid",0],["carotene","Carotene",0],["carvone","Carvone",0],["4un3","Cas9 bound to a target DNA",1],["6o0x","Cas9-sgRNA-DNA ternary complex",1],["catechol","Catechol",0],["chloroacetaldehyde","Chloroacetaldehyde",0],["chlorobenzene","Chlorobenzene",0],["chlorocresol","Chlorocresol",0],["chlorodifluoromethane","Chlorodifluoromethane",0],["chloroethyl","Chloroethyl",0],["chloromethane","Chloromethane",0],["chlorophyll","Chlorophyll",0],["chlorotrifluoromethane","Chlorotrifluoromethane",0],["cholesterol","Cholesterol",0],["chrysene","Chrysene",0],["cinnamic_acid","Cinnamic acid",0],["citrate","Citrate",0],["citric_acid","Citric acid",0],["cocaine","Cocaine",0],["1cag","Collagen",1],["coronene","Coronene",0],["cortisol","Cortisol",0],["coumarin","Coumarin",0],["cresol","Cresol",0],["cubane","Cubane",0],["curcumin","Curcumin",0],["curzerene","Curzerene",0],["cyanic_acid","Cyanic acid",0],["cyanuric_acid","Cyanuric acid",0],["cyclo_hexane","Cyclo hexane",0],["cyclo_hexene","Cyclo hexene",0],["cyclo_propane","Cyclo propane",0],["cyclobutane","Cyclobutane",0],["cyclobutanol","Cyclobutanol",0],["cyclobutylamine","Cyclobutylamine",0],["cyclohexadiene","Cyclohexadiene",0],["cycloicosane","Cycloicosane",0],["cyclooctene","Cyclooctene",0],["cyclopentenone","Cyclopentenone",0],["cyclopropene","Cyclopropene",0],["cysteine","Cysteine",0],["cytosine","Cytosine",0],["dasa","DASA",0],["1bna","DNA dodecamer",1],["decane","Decane",0],["1ok8","Dengue virus envelope glycoprotein",1],["deptropine","Deptropine",0],["diacetylene","Diacetylene",0],["diamond","Diamond",0],["diarylethene","Diarylethene",0],["diazepam","Diazepam",0],["diazepine","Diazepine",0],["diazomethane","Diazomethane",0],["dichloramine","Dichloramine",0],["dichlorodifluoroethylene","Dichlorodifluoroethylene",0],["diethyl_ether","Diethyl ether",0],["diethylamine","Diethylamine",0],["dimethyl_ether","Dimethyl ether",0],["dimethyl_hydrazine","Dimethyl hydrazine",0],["dimethyl_oxalate","Dimethyl oxalate",0],["dimethyl_sulfide","Dimethyl sulfide",0],["dimethylamine","Dimethylamine",0],["dinitrogen_oxide","Dinitrogen oxide",0],["dinitrogen_pentaoxide","Dinitrogen pentaoxide",0],["dinitrogen_tetroxide","Dinitrogen tetroxide",0],["dinitrotoluene","Dinitrotoluene",0],["dioxane","Dioxane",0],["dioxirane","Dioxirane",0],["dioxygen","Dioxygen",0],["diphenyl_ether","Diphenyl ether",0],["diphosphorus_tetraiodide","Diphosphorus tetraiodide",0],["disulfate","Disulfate",0],["disulfuric_acid","Disulfuric acid",0],["disulfurous_acid","Disulfurous acid",0],["dithionic_acid","Dithionic acid",0],["dithionous_acid","Dithionous acid",0],["dodecane","Dodecane",0],["dopamine","Dopamine",0],["ecstasy","Ecstasy",0],["eicosene","Eicosene",0],["epinephrine","Epinephrine",0],["erythrite","Erythrite",0],["erythromycin","Erythromycin",0],["erythrose","Erythrose",0],["estetrol","Estetrol",0],["estradiol","Estradiol",0],["estriol","Estriol",0],["estrol","Estrol",0],["estrone","Estrone",0],["ethanamide","Ethanamide",0],["ethane","Ethane",0],["ethanol","Ethanol",0],["ethoxyethane","Ethoxyethane",0],["ethyl_acetate","Ethyl acetate",0],["ethyl_alcohol","Ethyl alcohol",0],["ethyl_bromoacetate","Ethyl bromoacetate",0],["ethylene_glycol","Ethylene glycol",0],["fluorene","Fluorene",0],["fluorobenzene","Fluorobenzene",0],["fluoromethylene","Fluoromethylene",0],["formaldehyde","Formaldehyde",0],["formaldoxime","Formaldoxime",0],["formate","Formate",0],["formic_acid","Formic acid",0],["fulminic_acid","Fulminic acid",0],["fumarate","Fumarate",0],["fumaric_acid","Fumaric acid",0],["furaldehyde","Furaldehyde",0],["furan","Furan",0],["furfural","Furfural",0],["galactose","Galactose",0],["geraniol","Geraniol",0],["glucitol","Glucitol",0],["glucose","Glucose",0],["glutamic_acid","Glutamic acid",0],["glutamine","Glutamine",0],["glyceraldehyde","Glyceraldehyde",0],["glycerin","Glycerin",0],["glycerol","Glycerol",0],["glycine","Glycine",0],["glycol","Glycol",0],["graphene","Graphene",0],["graphite","Graphite",0],["1gfl","Green fluorescent protein",1],["guanine","Guanine",0],["gulose","Gulose",0],["hbdi","HBDI",0],["3lpu","HIV-1 integrase",1],["1dmp","HIV-1 protease",1],["1rev","HIV-1 reverse transcriptase",1],["1a3n","Hemoglobin",1],["heptane","Heptane",0],["hexafluorobenzene","Hexafluorobenzene",0],["hexahelicene","Hexahelicene",0],["histidine","Histidine",0],["1h58","Horseradish peroxidase",1],["1hgu","Human growth hormone",1],["1a4y","Human placental RNase inhibitor",1],["hydrazide","Hydrazide",0],["hydrogen_sulfate","Hydrogen sulfate",0],["hydrogen_sulfide","Hydrogen sulfide",0],["hydrosulfuric_acid","Hydrosulfuric acid",0],["ibuprofen","Ibuprofen",0],["ice","Ice",0],["idose","Idose",0],["1igt","Immunoglobulin",1],["indane","Indane",0],["indigo","Indigo",0],["indole","Indole",0],["inositol","Inositol",0],["3i40","Insulin",1],["iodobenzene","Iodobenzene",0],["iodomethane","Iodomethane",0],["isodrin","Isodrin",0],["isoleucine","Isoleucine",0],["isomaltol","Isomaltol",0],["isopropanol","Isopropanol",0],["isopropyl_alcohol","Isopropyl alcohol",0],["isovanillin","Isovanillin",0],["3kin","Kinesin",1],["laurencin","Laurencin",0],["lemonene","Lemonene",0],["leucine","Leucine",0],["linoleic_acid","Linoleic acid",0],["linolenic_acid","Linolenic acid",0],["lycopene","Lycopene",0],["lysine","Lysine",0],["lyxose","Lyxose",0],["malic_acid","Malic acid",0],["malonate","Malonate",0],["malonic_acid","Malonic acid",0],["maltol","Maltol",0],["mannitol","Mannitol",0],["mannose","Mannose",0],["melanin","Melanin",0],["melatonin","Melatonin",0],["menthol","Menthol",0],["methacrylic_acid","Methacrylic acid",0],["methane","Methane",0],["methanoic_acid","Methanoic acid",0],["methanol","Methanol",0],["methionine","Methionine",0],["methyl_acetate","Methyl acetate",0],["methyl_acrylate","Methyl acrylate",0],["methylpyrazine","Methylpyrazine",0],["methylthio","Methylthio",0],["methylthiophene","Methylthiophene",0],["1mbn","Myoglobin",1],["nanotube","Nanotube",0],["naphthalene","Naphthalene",0],["naphthol","Naphthol",0],["neopine","Neopine",0],["nicotine","Nicotine",0],["nitramide","Nitramide",0],["nitrate","Nitrate",0],["nitric_acid","Nitric acid",0],["nitrile","Nitrile",0],["nitrite","Nitrite",0],["nitroglycerine","Nitroglycerine",0],["nitromethane","Nitromethane",0],["nitrophenol","Nitrophenol",0],["nitropropane","Nitropropane",0],["nitrosamide","Nitrosamide",0],["nitrosomethane","Nitrosomethane",0],["nitrous_oxide","Nitrous oxide",0],["norbornane","Norbornane",0],["1aoi","Nucleosome core particle",1],["octane","Octane",0],["oleic_acid","Oleic acid",0],["ovalene","Ovalene",0],["oxalate","Oxalate",0],["oxalic_acid","Oxalic acid",0],["oxamic_acid","Oxamic acid",0],["oxirane","Oxirane",0],["oxytocin","Oxytocin",0],["ozone","Ozone",0],["palmitic_acid","Palmitic acid",0],["paracetamol","Paracetamol",0],["penicillin","Penicillin",0],["pentacene","Pentacene",0],["pentanal","Pentanal",0],["pentanol","Pentanol",0],["perchlorate","Perchlorate",0],["permanganate","Permanganate",0],["peroxide","Peroxide",0],["peroxide_ion","Peroxide ion",0],["peroxydisulfuric_acid","Peroxydisulfuric acid",0],["perylene","Perylene",0],["phenalene","Phenalene",0],["phenanthrene","Phenanthrene",0],["phenol","Phenol",0],["phenylalanine","Phenylalanine",0],["phosphine","Phosphine",0],["phosphoric_acid","Phosphoric acid",0],["phosphorus_pentachloride","Phosphorus pentachloride",0],["phosphorus_pentoxide","Phosphorus pentoxide",0],["phosphorus_trichloride","Phosphorus trichloride",0],["phosphoryl_chloride","Phosphoryl chloride",0],["1jb0","Photosystem I",1],["2axt","Photosystem II",1],["phthalate","Phthalate",0],["phthalic_acid","Phthalic acid",0],["piceid","Piceid",0],["picene","Picene",0],["picric_acid","Picric acid",0],["pinene","Pinene",0],["piperazine","Piperazine",0],["piperidinone","Piperidinone",0],["piperine","Piperine",0],["pivalic_acid","Pivalic acid",0],["polydatin","Polydatin",0],["porphyrin","Porphyrin",0],["progesterone","Progesterone",0],["proline","Proline",0],["propanal","Propanal",0],["propane","Propane",0],["propanediol","Propanediol",0],["propanol","Propanol",0],["propene","Propene",0],["propiolic_acid","Propiolic acid",0],["propionic_acid","Propionic acid",0],["propylene","Propylene",0],["prozac","Prozac",0],["pyran","Pyran",0],["pyranine","Pyranine",0],["pyrazinamide","Pyrazinamide",0],["pyrazine","Pyrazine",0],["pyrene","Pyrene",0],["pyridazine","Pyridazine",0],["pyridine","Pyridine",0],["pyrrole","Pyrrole",0],["pyrrolidine","Pyrrolidine",0],["pyruvate","Pyruvate",0],["pyruvic_acid","Pyruvic acid",0],["quercetin","Quercetin",0],["1i6h","RNA polymerase II",1],["remdesivir","Remdesivir",0],["resorcinol","Resorcinol",0],["resveratrol","Resveratrol",0],["retinal","Retinal",0],["rhodamine","Rhodamine",0],["ribose","Ribose",0],["6yb7","SARS-CoV-2 main protease",1],["6vxx","SARS-CoV-2 spike glycoprotein",1],["sarracine","Sarracine",0],["serine","Serine",0],["serotonin","Serotonin",0],["1bm0","Serum albumin",1],["silane","Silane",0],["1mel","Single-domain antibody in complex with lysozyme",1],["sorbic_acid","Sorbic acid",0],["sorbitol","Sorbitol",0],["spiropyran","Spiropyran",0],["stearic_acid","Stearic acid",0],["stilbene","Stilbene",0],["styrene","Styrene",0],["succinaldehyde","Succinaldehyde",0],["succinic_acid","Succinic acid",0],["sulfanilamide","Sulfanilamide",0],["sulfate","Sulfate",0],["sulfite","Sulfite",0],["sulfur_dioxide","Sulfur dioxide",0],["sulfur_hexafluoride","Sulfur hexafluoride",0],["sulfur_monoxide","Sulfur monoxide",0],["sulfur_tetrafluoride","Sulfur tetrafluoride",0],["sulfur_trioxide","Sulfur trioxide",0],["sulfuric_acid","Sulfuric acid",0],["sulfurous_acid","Sulfurous acid",0],["sulfuryl_chloride","Sulfuryl chloride",0],["sulfuryl_difluoride","Sulfuryl difluoride",0],["talose","Talose",0],["tartaric_acid","Tartaric acid",0],["tegretol","Tegretol",0],["testosterone","Testosterone",0],["tetracene","Tetracene",0],["tetrachloromethane","Tetrachloromethane",0],["tetracyanomethane","Tetracyanomethane",0],["tetrafluoroethylene","Tetrafluoroethylene",0],["tetrafluoromethane","Tetrafluoromethane",0],["thc","Tetrahydrocannabinol (THC)",0],["tetrahydrofuran","Tetrahydrofuran",0],["thf","Tetrahydrofuran (THF)",0],["6d6v","Tetrahymena telomerase",1],["thionyl_difluoride","Thionyl difluoride",0],["thiosulfate","Thiosulfate",0],["thiosulfuric_acid","Thiosulfuric acid",0],["thiosulfurous_acid","Thiosulfurous acid",0],["threonine","Threonine",0],["threose","Threose",0],["thymine","Thymine",0],["thyroxine","Thyroxine",0],["4tna","Transfer RNA",1],["1muh","Transposase",1],["trichloromethane","Trichloromethane",0],["trifluoroacetaldehyde","Trifluoroacetaldehyde",0],["triiodothyronine","Triiodothyronine",0],["triphenylamine","Triphenylamine",0],["triphenylene","Triphenylene",0],["tryptophan","Tryptophan",0],["tyrosine","Tyrosine",0],["undecane","Undecane",0],["undecanone","Undecanone",0],["uracil","Uracil",0],["urea","Urea",0],["urocanic_acid","Urocanic acid",0],["valeric_acid","Valeric acid",0],["valine","Valine",0],["valium","Valium",0],["vanillic_acid","Vanillic acid",0],["vinyl_acetate","Vinyl acetate",0],["vinyl_chloride","Vinyl chloride",0],["vitamin_b","Vitamin B",0],["vitamin_c","Vitamin C",0],["vitamin_d","Vitamin D",0],["vitamin_e","Vitamin E",0],["vitamin_k","Vitamin K",0],["water","Water",0],["xanthene","Xanthene",0],["xylose","Xylose",0]];

  const navData = [
    {"type": "category", "name": "Showcase", "children": [
      {"type": "molecule", "name": "6vxx"},
      {"type": "molecule", "name": "1a3n"},
      {"type": "molecule", "name": "3i40"},
      {"type": "molecule", "name": "1bna"},
      {"type": "molecule", "name": "1aoi"},
      {"type": "molecule", "name": "1dmp"},
      {"type": "molecule", "name": "water"},
      {"type": "molecule", "name": "caffeine"},
      {"type": "molecule", "name": "ice"},
      {"type": "molecule", "name": "graphene"},
      {"type": "molecule", "name": "nanotube"},
      {"type": "molecule", "name": "buckyball"}
    ]},
    {"type": "category", "name": "Biomolecules", "children": [
      {"type": "molecule", "name": "6vxx"},
      {"type": "molecule", "name": "6yb7"},
      {"type": "molecule", "name": "1aoi"},
      {"type": "molecule", "name": "4un3"},
      {"type": "molecule", "name": "1a3n"},
      {"type": "molecule", "name": "1mbn"},
      {"type": "molecule", "name": "3i40"},
      {"type": "molecule", "name": "1bna"},
      {"type": "molecule", "name": "4tna"},
      {"type": "molecule", "name": "1igt"},
      {"type": "molecule", "name": "1jb0"},
      {"type": "molecule", "name": "2axt"},
      {"type": "molecule", "name": "1cag"},
      {"type": "molecule", "name": "1rev"},
      {"type": "molecule", "name": "1dmp"},
      {"type": "molecule", "name": "3lpu"},
      {"type": "molecule", "name": "6o0x"},
      {"type": "molecule", "name": "3kin"},
      {"type": "molecule", "name": "1i6h"},
      {"type": "molecule", "name": "1a4y"},
      {"type": "molecule", "name": "1ok8"},
      {"type": "molecule", "name": "1hgu"},
      {"type": "molecule", "name": "6d6v"},
      {"type": "molecule", "name": "1mel"},
      {"type": "molecule", "name": "1gfl"},
      {"type": "molecule", "name": "1bm0"},
      {"type": "molecule", "name": "1h58"}
    ]},
    {"type": "category", "name": "Amino acids", "children": [
      {"type": "molecule", "name": "alanine"},
      {"type": "molecule", "name": "arginine"},
      {"type": "molecule", "name": "asparagine"},
      {"type": "molecule", "name": "aspartic_acid"},
      {"type": "molecule", "name": "cysteine"},
      {"type": "molecule", "name": "glutamine"},
      {"type": "molecule", "name": "glutamic_acid"},
      {"type": "molecule", "name": "glycine"},
      {"type": "molecule", "name": "histidine"},
      {"type": "molecule", "name": "isoleucine"},
      {"type": "molecule", "name": "leucine"},
      {"type": "molecule", "name": "lysine"},
      {"type": "molecule", "name": "methionine"},
      {"type": "molecule", "name": "phenylalanine"},
      {"type": "molecule", "name": "proline"},
      {"type": "molecule", "name": "serine"},
      {"type": "molecule", "name": "threonine"},
      {"type": "molecule", "name": "tryptophan"},
      {"type": "molecule", "name": "tyrosine"},
      {"type": "molecule", "name": "valine"}
    ]},
    {"type": "category", "name": "Nucleobases", "children": [
      {"type": "molecule", "name": "cytosine"},
      {"type": "molecule", "name": "guanine"},
      {"type": "molecule", "name": "adenine"},
      {"type": "molecule", "name": "thymine"},
      {"type": "molecule", "name": "uracil"}
    ]},
    {"type": "category", "name": "Sugar", "children": [
      {"type": "molecule", "name": "glyceraldehyde"},
      {"type": "molecule", "name": "erythrose"},
      {"type": "molecule", "name": "threose"},
      {"type": "molecule", "name": "ribose"},
      {"type": "molecule", "name": "arabinose"},
      {"type": "molecule", "name": "xylose"},
      {"type": "molecule", "name": "lyxose"},
      {"type": "molecule", "name": "allose"},
      {"type": "molecule", "name": "altrose"},
      {"type": "molecule", "name": "glucose"},
      {"type": "molecule", "name": "mannose"},
      {"type": "molecule", "name": "gulose"},
      {"type": "molecule", "name": "idose"},
      {"type": "molecule", "name": "galactose"},
      {"type": "molecule", "name": "talose"}
    ]},
    {"type": "category", "name": "Polycyclic aromatic hydrocarbons", "children": [
      {"type": "molecule", "name": "naphthalene"},
      {"type": "molecule", "name": "biphenyl"},
      {"type": "molecule", "name": "fluorene"},
      {"type": "molecule", "name": "anthracene"},
      {"type": "molecule", "name": "phenanthrene"},
      {"type": "molecule", "name": "phenalene"},
      {"type": "molecule", "name": "tetracene"},
      {"type": "molecule", "name": "chrysene"},
      {"type": "molecule", "name": "pyrene"},
      {"type": "molecule", "name": "pentacene"},
      {"type": "molecule", "name": "perylene"},
      {"type": "molecule", "name": "coronene"},
      {"type": "molecule", "name": "ovalene"}
    ]},
    {"type": "category", "name": "Chromophores", "children": [
      {"type": "molecule", "name": "rhodamine"},
      {"type": "molecule", "name": "coumarin"},
      {"type": "molecule", "name": "indigo"},
      {"type": "molecule", "name": "stilbene"},
      {"type": "molecule", "name": "retinal"},
      {"type": "molecule", "name": "carotene"},
      {"type": "molecule", "name": "azobenzene"},
      {"type": "molecule", "name": "bodipy"},
      {"type": "molecule", "name": "diarylethene"},
      {"type": "molecule", "name": "dasa"},
      {"type": "molecule", "name": "hbdi"},
      {"type": "molecule", "name": "spiropyran"}
    ]}
  ];

  const idToMolecule = {};
  for (const row of database) {
    idToMolecule[row[0]] = row;
  }

  let searchResults = [];
  let selectedCategory = 0;
  let isSearching = false;

  const isAndroid = navigator.userAgent.toLowerCase().indexOf("android") != -1;

  const apiRequest = function(type, url, data) {
    return new Promise(function(resolve, reject) {
      const xhr = new XMLHttpRequest();
      xhr.onreadystatechange = function() {
        if (xhr.readyState === 4) {
          if (xhr.status === 200) {
            let response = xhr.responseText;
            let contentType = xhr.getResponseHeader("Content-Type");
            if (contentType !== null) {
              const i = contentType.indexOf(";");
              if (i != -1)
                contentType = contentType.substr(0, i);
              if (contentType == "application/json")
                response = JSON.parse(response);
            }
            resolve(response);
          } else {
            reject();
          }
        }
      };
      xhr.open(type, url);
      // xhr.setRequestHeader("X-Requested-With", "XMLHttpRequest");
      if ((type == "POST" || type == "PUT") && data !== undefined) {
        //xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8");
        xhr.setRequestHeader("Content-Type", "application/json; charset=UTF-8");
        xhr.send(JSON.stringify(data));
      } else {
        xhr.send();
      }
    });
  };

  const modal = new bootstrap.Modal(document.getElementById("viewerModal"));
  function showModelViewer(event) {
    event.preventDefault();
    const name = this.getAttribute("data-name");
    const title = this.getAttribute("data-title");
    const usdzURL = modelPath + "/models/" + name + ".usdz";
    const glbURL = modelPath + "/models/" + name + ".glb";

    document.getElementById("viewerModalLabel").textContent = title;
    document.getElementById("usdzLink").href = usdzURL;
    document.getElementById("glbLink").href = glbURL;
    const viewerModalBody = document.getElementById("viewerModalBody");
    const modelViewer = document.createElement("model-viewer");
    modelViewer.style.width = "100%";
    modelViewer.style.height = "400px";
    modelViewer.src = glbURL;
    modelViewer.cameraControls = true;
    modelViewer.environmentImage = "img/lightroom_14b.hdr";
    modelViewer.exposure = 0.5;
    modelViewer.setAttribute("data-js-focus-visible", ""); // To hide outline in Safari.

    viewerModalBody.textContent = "";
    viewerModalBody.appendChild(modelViewer);

    document.getElementById("qrcode").textContent = "";
    new QRCode(document.getElementById("qrcode"), {
      text: "https://" + window.location.host + window.location.pathname + "?name=" + name,
      width: 100,
      height: 100,
      colorDark : "#000000",
      colorLight : "#ffffff",
      correctLevel : QRCode.CorrectLevel.H
    });

    modal.show();
  }

  function createLink(molecule) {
    const cell = molecule[0];
    const a = document.createElement("a");
    if (isAndroid) {
      const glbURL = modelPath + "/models/" + cell + ".glb";
      const fallbackURL = "https://arvr.google.com/scene-viewer?file=" + encodeURIComponent(glbURL) + "&mode=ar_preferred";
      a.href = "intent://arvr.google.com/scene-viewer/1.0?file=" + glbURL + "&mode=ar_preferred#Intent;scheme=https;package=com.google.android.googlequicksearchbox;action=android.intent.action.VIEW;S.browser_fallback_url=" + fallbackURL + ";end;";
    } else if (a.relList.supports("ar")) {
      a.rel = "ar";
      a.href = modelPath + "/models/" + cell + ".usdz";
    } else {
      a.href = "#";
      a.setAttribute("data-name", cell);
      a.setAttribute("data-title", molecule[1]);
      a.addEventListener("click", showModelViewer);
    }

    const img = document.createElement("img");
    img.src = modelPath + "/img/previews/" + cell + ".png";
    img.className = "molecule-img";
    img.width = 250;
    img.height = 250;
    img.alt = molecule[1];
    a.appendChild(img);

    if (molecule[2]) { // PDB
      let spinner;
      const timer = setTimeout(() => {
        spinner = document.createElement("div");
        spinner.className = "spinner-border text-secondary";
        a.appendChild(spinner);
      }, 1000);
      const hideSpinner = () => {
        clearTimeout(timer);
        if (spinner)
          a.removeChild(spinner);
      };
      img.addEventListener("load", hideSpinner);
      img.addEventListener("error", hideSpinner);
    }
    return a;
  }

  function renderCell(molecule) {
    const cell = molecule[0];
    const col = document.createElement("div");
    col.className = "col-sm-12 col-md-6 col-xl-4";
    const div = document.createElement("div");
    div.className = "molecule";

    const a = createLink(molecule);
    div.appendChild(a);
    col.appendChild(div);

    const h = document.createElement("div");
    h.className = "molecule-name";
    if (molecule[2]) {
      h.innerHTML = molecule[1] + " <span class='pdb-id'>(<a href='https://www.rcsb.org/structure/" + molecule[0] + "' target='_blank' rel='noreferrer' rel='noopener'>" + molecule[0].toUpperCase() + "</a>)</span>";
    } else {
      h.textContent = molecule[1];
    }
    col.appendChild(h);

    return col;
  }

  function renderTable(element, cells) {
    const row = document.createElement("div");
    row.className = "row g-3 moleculeTable";
    for (const cell of cells) {
      row.appendChild(renderCell(cell));
    }
    element.textContent = "";
    element.appendChild(row);
  }


  function renderPageControl(element, nPages, page) {
    const toolbar = document.createElement("div");
    toolbar.className = "btn-toolbar mb-3 pageControl";
    const buttonGroup = document.createElement("div");
    buttonGroup.className = "btn-group me-2";

    const l = Math.max( Math.min(page - 1, nPages - 5), 0);
    const r = Math.min( Math.max(page + 1, 4), nPages - 1);
    const pages = []; // The length of this will be Math.min(nPages, 7)
    if (l > 0) {
      pages.push(0);
      if (l > 1) {
        pages.push((l == 2) ? 1 : -1);
      }
    }
    for (let i = l; i <= r; ++i) {
      pages.push(i);
    }
    if (r < nPages - 1) {
      if (r < nPages - 2) {
        pages.push((r == nPages - 3) ? nPages - 2 : -1);
      }
      pages.push(nPages - 1);
    }

    {
      const button = document.createElement("button");
      button.type = "button";
      button.className = "btn btn-outline-secondary";
      button.textContent = "<";
      button.addEventListener("click", () => {
        renderResults(page - 1);
      });
      if (page == 0)
        button.disabled = true;
      buttonGroup.appendChild(button);
    }
    for (const i of pages) {
      const button = document.createElement("button");
      button.type = "button";
      button.className = (i == page) ? "btn btn-secondary" : "btn btn-outline-secondary";
      buttonGroup.appendChild(button);
      if (i == -1) {
        button.textContent = "...";
        button.addEventListener("click", () => {
          const page = prompt("Go to page ...");
          if (page !== null)
            renderResults(page - 1);
        });
      } else {
        button.textContent = i + 1;
        button.addEventListener("click", () => {
          if (i == page)
            return;
          renderResults(i);
        });
      }
    }
    {
      const button = document.createElement("button");
      button.type = "button";
      button.className = "btn btn-outline-secondary";
      button.textContent = ">";
      button.addEventListener("click", () => {
        renderResults(page + 1);
      });
      if (page == nPages - 1)
        button.disabled = true;
      buttonGroup.appendChild(button);
    }
    toolbar.appendChild(buttonGroup);
    element.textContent = "";
    element.appendChild(toolbar);
  }

  const perPage = 12;
  function renderResults(page = 0) {
    const results = searchResults;
    const nPages = Math.max(Math.ceil(results.length / perPage), 1);
    if (isNaN(page) || page < 0 || page >= nPages)
      return;
    const start = page * perPage;
    const end = (page + 1) * perPage;
    renderTable(document.getElementById("out"), results.slice(start, end));
    if (results.length > 0 && (selectedCategory != 0 || isSearching) && (results.length > 1 || !isSearching)) {
      renderPageControl(document.getElementById("pageControl"), nPages, page);
      renderPageControl(document.getElementById("pageControl2"), nPages, page);
    } else {
      document.getElementById("pageControl").textContent = "";
      document.getElementById("pageControl2").textContent = "";
    }
  }

  function clearSearch() {
    searchResults = [];
    isSearching = false;
    document.getElementById("searchResults-summary").textContent = "";
    document.getElementById("clearSearch").style.display = "none";
    renderViews();
  }

  async function searchMolecule(name) {
    const molecule = idToMolecule[name];
    if (molecule !== undefined)
      return molecule;
    if (/^[1-9][\da-z]{3}$/.test(name)) { // PDB
      let data;
      try {
        data = await apiRequest("GET", "https://data.rcsb.org/rest/v1/core/entry/" + name);
      } catch (error) {
      }
      if (data)
        return [name, data.struct.title, 1];
    }
    return null;
  }

  document.getElementById("searchForm").addEventListener("submit", (event) => {
    event.preventDefault();
    document.getElementById("searchBar").blur();
  });

  const spaceRegExp = / /g;
  document.getElementById("searchBar").addEventListener("input", async (event) => {
    event.preventDefault();
    const countySearch = document.getElementById("searchBar");
    const originalQuery = countySearch.value;
    let query = originalQuery.trim();
    if (query.length == 0) {
      clearSearch();
      return;
    }
    isSearching = true;
    query = query.toLowerCase();
    const results = [];
    const summary = document.getElementById("searchResults-summary");

    if (/^[1-9][\da-z]{3}$/.test(query)) { // PDB
      summary.textContent = 'PDB ID “' + query.toUpperCase() + '”';
      const result = await searchMolecule(query);
      if (result) {
        results.push(result);
      } else {
        summary.textContent = 'PDB ID “' + query.toUpperCase() + '”: Not found';
      }
    } else if (/^[1-9][\da-z]{0,2}$/.test(query)) { // Partial PDB
      summary.textContent = 'PDB ID “' + query.toUpperCase() + '...”';
    } else {
      for (const row of database) {
        const tmp = row[1].toLowerCase();
        if (tmp.startsWith(query) || tmp.indexOf(" " + query) != -1 || tmp.indexOf("(" + query) != -1 || tmp.replace(spaceRegExp, "").startsWith(query))
          results.push(row);
      }
      if (results.length == 0) {
        summary.textContent = "No results found for “" + originalQuery + "”";
      } else {
        summary.textContent = "Found " + results.length + " result" + ((results.length != 1) ? "s" : "") + " for “" + originalQuery + "”";
      }
    }
    searchResults = results;

    document.getElementById("clearSearch").style.display = "inline";
    renderViews();
  });

  document.getElementById("clearSearch").addEventListener("click", (event) => {
    event.preventDefault();
    document.getElementById("searchBar").value = "";
    clearSearch();
  });


  function renderViews() {
    const nav = document.getElementById("nav");
    nav.textContent = "";

    for (let i = 0; i < navData.length; ++i) {
      const category = navData[i];
      const li = document.createElement("li");
      li.className = "nav-item";
      const a = document.createElement("a");
      a.className = "nav-link" + ((i == selectedCategory && !isSearching) ? " active" : "");
      a.textContent = category.name;
      a.href = "#";
      a.addEventListener("click", (event) => {
        event.preventDefault();
        selectedCategory = i;
        isSearching = false;
        document.getElementById("searchBar").value = "";
        renderViews();
      });
      li.appendChild(a);
      nav.appendChild(li);

      if (i == 0) {
        const li = document.createElement("li");
        li.className = "nav-item nav-separator";
        nav.appendChild(li);
      }
    }

    if (!isSearching) {
      const category = navData[selectedCategory];
      document.getElementById("searchResults-summary").textContent = category.name;
      searchResults = [];
      for (const molecule of category.children) {
        searchResults.push(idToMolecule[molecule.name]);
      }
      document.getElementById("clearSearch").style.display = "none";
    }

    // To hide the nav on small screens when searching.
    document.getElementById("navCol").className = isSearching ? "col-sm-4 col-md-3 d-none d-sm-block" : "col-sm-4 col-md-3 d-sm-block";

    renderResults();
  }

  renderViews();

  if (window.URLSearchParams) {
    const params = new URLSearchParams(window.location.search);
    const name = params.get("name");
    if (name) {
      (async () => {
        const molecule = await searchMolecule(name);
        createLink(molecule).click();
      })();
    }
  }
})();
