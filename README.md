This repository contains the source code of MolAR, an app for chemistry in augmented reaility.

When using MolAR in research, please cite Sukolsak Sakshuwong, Hayley Weir, Umberto Raucci, Todd J. Martínez. [MolAR: Bringing Chemical Structures to Life with Augmented Reality and Machine Learning](https://chemrxiv.org/engage/chemrxiv/article-details/613081028e38a3bd644709da). ChemRxiv.

MolAR has 2 components:
- iOS app
- web server: mediates between the iOS app and cloud services

## Web server

Requirements: Python, pip, Mathpix account, AWS account (for Amazon Rekognition), Google Cloud account (for Google Cloud Vision API), and TeraChem Cloud account.

1. `cd server`
1. `pip install httpx boto3 google-cloud-vision tccloud fastapi uvicorn`
1. To use the chemical structure recognition feature, create a [Mathpix](https://mathpix.com) account and set the following environment variables:
   - `MATHPIX_APP_ID`
   - `MATHPIX_APP_KEY`
1. To use the object recognition feature, follow the instructions on [Getting started with Amazon Rekognition](https://docs.aws.amazon.com/rekognition/latest/dg/getting-started.html), then set the following environment variables:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`

    Then follow the instructions on [Google Cloud: Setup the Vision API](https://cloud.google.com/vision/docs/setup), and put service-account-file.json in the current folder.
1. To use the quantum computation feature, contact the [Martinez group](https://mtzweb.stanford.edu) to get a TeraChem Cloud account. Then set the following environment variables:
   - `TCCLOUD_USER`
   - `TCCLOUD_PWD`
1. `uvicorn main:app --reload --host 0.0.0.0 --port 8080`

## iOS app

Requirements: macOS Big Sur or later, Xcode 12 or later.

1. `cd ios/MolAR`
1. `cp Config.swift.example Config.swift`
1. Edit Config.swift, set the web server address. Then save.
1. Open the project in Xcode and run.
