from fastapi import FastAPI, File
from pydantic import BaseModel
import json
import httpx
import asyncio
import concurrent.futures
from os import getenv
from google.cloud import vision
import boto3
from botocore.exceptions import ClientError

from tccloud import TCClient
from tccloud.models import AtomicInput, FutureResult


client = TCClient(tccloud_username=getenv("TCCLOUD_USER"),
                  tccloud_password=getenv("TCCLOUD_PWD"))

app = FastAPI(docs_url=None, redoc_url=None)


def parse_xyz(xyz):
    to_bohr = 1.88972
    symbols = []
    geometry = []
    lines = xyz.split("\n")
    n_atoms = int(lines[0])
    for line in lines[2:2 + n_atoms]:
        columns = line.split()
        assert len(columns) == 4
        symbols.append(columns[0])
        geometry.append(float(columns[1]) * to_bohr)
        geometry.append(float(columns[2]) * to_bohr)
        geometry.append(float(columns[3]) * to_bohr)
    return symbols, geometry


def get_epsilon(solvent):
    solvents = {
        'vacuum': None,
        'water': 78.35,
        'acetonitrile': 35.69,
        'methanol': 32.61,
        'ethanol': 24.85,
        'chloroform': 4.71,
        'dichloromethane': 8.93,
        'toluene': 2.37,
        'cyclohexane': 2.02,
        'acetone': 20.49,
        'tetrahydrofuran': 7.43,
        'dimethylsulfoxide': 46.83
    }
    epsilon = solvents[solvent]
    return epsilon


def recognize_image_helper_google(file):
    client = vision.ImageAnnotatorClient.from_service_account_json(
        'service-account-file.json')
    image = vision.Image(content=file)
    response = client.label_detection(image=image)
    labels = response.label_annotations

    return [{"description": label.description, "score": label.score} for label in labels]


def recognize_image_helper_aws(file):
    rekognition_client = boto3.client(
        "rekognition",
        aws_access_key_id=getenv("AWS_ACCESS_KEY_ID"),
        aws_secret_access_key=getenv("AWS_SECRET_ACCESS_KEY"),
        region_name=getenv("AWS_REGION_NAME")
    )
    try:
        response = rekognition_client.detect_labels(Image={"Bytes": file}, MaxLabels=10)
        labels = response['Labels']
    except ClientError:
        return []

    return [{"description": label.get("Name"), "score": label.get("Confidence")} for label in labels]


def obj_to_molecules(obj):
    database = {
        # Vegetables: data from Chemical Composition of Vegetables and their Products (Handbook of Food Chemistry, DOI 10.1007/978-3-642-41609-5_17-1)
        "asparagus": ["asparagusic acid", "folic acid", "malic acid", "citric acids", "methanethiol"],
        "bean": ["silicic acid", "phytin", "phaseolin"],
        "broccoli": ["ubiquinone", "lipoic acid", "sulforaphane", "glucoraphanin", "chlorophyll"],
        "cabbage": ["myo-inositol", "folic acid"],
        "carrot": ["carotene", "retinal", "retinoic acid"],
        "cauliflower": ["sulforaphane", "diindolylmethane", "glucosinolates", "isothiocyanate"],
        "celery": ["falcarindiol", "eugenic acid", "sedanolide", "lunularin", "obsthol", "umbelliferone"],
        "cucumber": ["tartaric acid", "avenasterol", "spinasterol", "karounidiol", "isokarounidiol", "luteolin", "quercetin"],
        "dill": ["eugenol", "phellandrene", "anethole", "terpinene", "carvone", "oxypeucedanin"],
        "eggplant": ["isoscopoletin", "vanillin", "ethyl caffeate", "ferulic acid", "feruloyltyramine", "solasodin"],
        "garlic": ["allicin", "alliin", "ajoene", "kaempferol"],
        "leek": ["folate"],
        "lentil": ["tricetin", "luteolin", "rutin", "quercetin", "chiro-inositol"],
        "lettuce": ["lactucin", "chlorophyll"],
        "onion": ["propanethial-S-oxide", "alliin", "cycloallin", "quercetin"],
        "parsley": ["myristicin", "terpinene", "apiol", "terpinolene", "cineol", "psoralen"],
        "pea": ["uric acid", "pisatin"],
        "pepper": ["luteolin", "capsorubin", "capsanthin", "capsaicin"],
        "potato": ["tuberin", "solasonine", "solamargine", "tomatine"],
        "pumpkin": ["leucine", "tocopherol", "sitosterol"],
        "radishes": ["phenethylamine", "cytokinin", "diaminotoluene"],
        "rice": ["amylopectin", "amylose"],
        "spinach": ["spinacetin", "spinasterol", "neoxanthin", "carotene", "chlorophyll", "violaxanthin", "stigmasterol"],
        "tomato": ["lycopene", "carotene", "tomatidin"],
        "turnip": ["folate", "sinigrin", "glucobrassicin"],

        "salt": ["sodium chloride"],
        "sugar": ["sucrose"],
        # "oil": [],

        # Fruits: from https://jameskennedymonash.wordpress.com/category/infographics/all-natural-banana-and-other-fruits/ +
        # https://www.compoundchem.com/tag/fruit/

        "mango": ["ethyl butanoate"],
        "blackberry": ["cyanidin 3-glucoside"],
        "cherry": ["malic acid"],
        "prune": ["sorbitol"],
        "watermelon": ["3,6-nonadienal"],
        "avocado": ["catechol"],
        "lemon": ["citric acid"],
        "orange": ["vitamin c"],
        "banana": ["isoamyl acetate"],
        "pineapple": ["ethyl butanoate"],
        "peach": ["gamma-undecalactone"],
        "kiwi": ["vitamin c"],
        "passionfruit": ["methyl butanoate"],
        "strawberry": ["pelargonidin 3-glucoside"],
        "apple": ["flavan-3-ol"],
        "grape":  ["resveratrol"],
        "pear": ["choline"],
        "blueberry": ["anthocyanin"],
        "nutmeg": ["myristicin"],

        # Beverages:
        "coffee": ["caffeine"],
        "tea": ["caffeine"],
        "water": ["water"],
        "wine": ["ethanol", "resveratrol"],
        "beer": ["ethanol"],
        "juice": ["vitamin c"],
        "milk": ["lactose"],

        "ice cream": ["lactose"],

        "mushroom": ["riboflavin", "niacin", "pantothenic acid"],
        "rose": ["vitamin c"],

        "artichoke": ["vitamin c"],
        "egg": ["1ova"],
        "leaf": ["chlorophyll"],
        "chocolate": ["phenylethylamine"],
        "meat": ["1mbo"],
        "hand": ["1bna"],
        "arm": ["1bna"],
        "leg": ["1bna"],
        "skin": ["1cag"],


        "pc": ["silicon"],
        "laptop": ["silicon"],
        "computer": ["silicon"],

        #"pizza": ["heart"],

        "dog": ["1bna"],
    }

    if obj in database:
        results = database[obj]
    else:
        results = None
    return results


async def recognize_image(file: bytes = File(...)):
    loop = asyncio.get_running_loop()
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        objs, objs2 = await asyncio.gather(
            loop.run_in_executor(pool, recognize_image_helper_google, file),
            loop.run_in_executor(pool, recognize_image_helper_aws, file)
        )
    objs += objs2

    match = False
    for obj in objs:
        for subobj in obj["description"].lower().split():
            matching = obj_to_molecules(subobj)
            if matching is not None:
                tmp = {"object": subobj, "molecules": matching}
                match = True
                break
        if match:
            break

    if not match:
        tmp = {"object": objs[0]["description"].lower(), "molecules": []}

    return {
        "labels": tmp
    }




# -------------------------------------------------------------------------------
# APIs for MolAR

class MolARCalculateSinglePointRequest(BaseModel):
    xyz: str
    open_smiles: str
    method: str
    basis: str
    molecular_charge: int
    molecular_multiplicity: int
    phase: str
    cis: bool

@app.post("/api/molar_calculate_single_point")
async def molar_calculate_single_point(data: MolARCalculateSinglePointRequest):
    xyz = data.xyz
    open_smiles = data.open_smiles
    method = data.method
    basis = data.basis
    molecular_charge = data.molecular_charge
    molecular_multiplicity = data.molecular_multiplicity
    solvent = data.phase
    cis = data.cis

    symbols, geometry = parse_xyz(xyz)
    epsilon = get_epsilon(solvent)

    if epsilon:
        pcm = "cosmo"
    else:
        pcm = "no pcm"
        epsilon = 0.0

    if method == "gfn2xtb":
        basis = "gfn2xtb"
        sphericalbasis = "yes"
    else:
        sphericalbasis = "no"

    if cis:
        cis = 'yes'
    else:
        cis = 'no'

    molecule = {
        "symbols": symbols,
        "geometry": geometry,
        "molecular_charge": molecular_charge,
        "molecular_multiplicity": molecular_multiplicity,
    }
    model = {
        "method": method,
        "basis": basis,
    }
    keywords = {
        "molden": True,
        "mo_output": True,
        "pcm": pcm,
        "epsilon": epsilon,
        "sphericalbasis": sphericalbasis,
        "cis": cis,
        "cisnumstates": 5,
    }
    protocols = {
        "wavefunction": "all"
    }

    atomic_input = AtomicInput(molecule=molecule,
                               model=model,
                               keywords=keywords,
                               protocols=protocols,
                               driver="energy")

    future_result = client.compute(atomic_input, engine="terachem_pbs")

    result = {
        "task":future_result.task_id,
    }

    return result



class MolARCheckRequest(BaseModel):
    task_id: str

@app.post("/api/molar_check_results")
async def molar_check_results(data: MolARCheckRequest):
    task = data.task_id

    fr = FutureResult(client=client._client, task_id=task)
    status = fr.status
    status = status.split()[-1]

    if status == "SUCCESS":
        data = fr.get()
        result = {
            "status": status,
            "molden": data.dict()["extras"]["molden"],
            "dipole": data.dict()["properties"]["scf_dipole_moment"].tolist(),
        }
    else:
        result = {
            "status": status
        }

    return result


@app.post("/api/molar_recognize_object")
async def molar_recognize_object(file: bytes = File(...)):
    result = await recognize_image(file)
    return result["labels"]


@app.post("/api/molar_recognize_structure")
async def molar_recognize_structure(file: bytes = File(...)):
    async with httpx.AsyncClient() as client:
        response = await client.post("https://api.mathpix.com/v3/text", files={"file": file}, data={
            "options_json": json.dumps({
                "formats": ["text"],
                "include_smiles": True
            })
        }, headers={
            "app_id": getenv("MATHPIX_APP_ID"),
            "app_key": getenv("MATHPIX_APP_KEY")
        })
    r = response.json()
    smileses = []
    if "text" in r:
        text = r["text"]
        i = text.find("<smiles>")
        if i != -1:
            j = text.find("</smiles>", i + 8)
            if j != -1:
                smileses = [text[i+8:j]]
    return {
        "molecules": smileses
    }


@app.post("/api/molar_recognize_drawing")
async def molar_recognize_drawing(file: bytes = File(...)):
    return await molar_recognize_structure(file)
