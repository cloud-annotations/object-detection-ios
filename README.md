# Object Detection iOS App

You can find an in depth walkthrough for training a Core ML model [here](https://github.com/cloud-annotations/training/).

## Setup
`git clone` the repo and `cd` into it by running the following command:

```bash
git clone https://github.com/cloud-annotations/object-detection-ios.git
cd object-detection-ios
```

## Add your model files to the project
Copy the `model_ios` directory generated from the classification walkthrough and paste it into the `object-detection-ios/Core ML Object Detection` folder of this repo.

## Install Xcode
In order to develop for iOS we need to first install the latest version of Xcode, which can be found on the [Mac App Store](https://itunes.apple.com/us/app/xcode/id497799835?mt=12)

## Open the project with Xcode
Launch Xcode and choose **Open another project...**
![](https://d2mxuefqeaa7sj.cloudfront.net/s_50BD1551C2CA022B9CF9D8DF0A28275DB7ACF3DBDD5764C0CB12B3AF3B1E0766_1541995654686_Screen+Shot+2018-11-11+at+10.18.30+PM.png)

Then in the file selector, choose `object-detection-ios`.

## Test the application in the simulator
Now we’re ready to test! First we’ll make sure the app builds on our computer, if all goes well, the simulator will open and the app will display.

To run in the simulator, select an iOS device from the dropdown and click **run**.
![](https://d2mxuefqeaa7sj.cloudfront.net/s_50BD1551C2CA022B9CF9D8DF0A28275DB7ACF3DBDD5764C0CB12B3AF3B1E0766_1541996500409_Screen+Shot+2018-11-11+at+10.25.24+PM2.png)

## Or run the app on an iOS device
Since the simulator does not have access to a camera, and the app relies on the camera to test the classifier, we should also run it on a real device.


1. Select the project editor (*The name of the project with a blue icon*)
1. Under the **Signing** section, click **Add Account**
![](https://bourdakos1.github.io/deprecated-cloud-annotations/assets/add_account.png)
1. Login with your Apple ID and password
![](https://bourdakos1.github.io/deprecated-cloud-annotations/assets/xcode_add_account.png)
1. *You should see a new personal team created*
1. Close the preferences window

Now we have to create a certificate to sign our app with
1. Select **General**
1. Change the **bundle identifier** to `com.<YOUR_LAST_NAME>.Core-ML-Vision`
![](https://bourdakos1.github.io/deprecated-cloud-annotations/assets/change_identifier.png)
1. Select the personal team that was just created from the **Team** dropdown
1. Plug in your iOS device
1. Select your device from the device menu to the right of the **build and run** icon
1. Click **build and run**
1. On your device, you should see the app appear as an installed appear
1. When you try to run the app the first time, it will prompt you to approve the developer
1. In your iOS settings navigate to ***General > Device Management***
1. Tap your email, tap **trust**

Now you're ready to run the app!
