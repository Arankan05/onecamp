# OneCamp -- Shared Image Storage Configuration

## 1. Purpose

OneCamp uses **Cloudinary** as its shared image-hosting service instead
of Firebase Storage.

The reason given by the team is that Firebase Storage is not enabled
because it requires a Firebase billing account. The team will therefore
upload images to Cloudinary and save the resulting image URL in Cloud
Firestore.

All six team members use the same Cloudinary account, but each feature
has its own **unsigned upload preset** and Cloudinary folder.

## 2. Shared Cloudinary configuration

  Setting                 Value
  ----------------------- ----------------------------------------
  Cloudinary cloud name   `o5k43wz7`
  Upload signing mode     Unsigned
  Account arrangement     One shared account for all six members

## 3. Member-specific upload presets

Use only the preset assigned to your feature.

  ------------------------------------------------------------------------------------
  Team member       Feature           Upload preset                  Cloudinary folder
  ----------------- ----------------- ------------------------------ -----------------
  Member 1          Profile images    `onecamp_profile_images`       `profiles`

  Member 2          Feed images       `onecamp_feed_images`          `feed`

  Member 3          Community images  `onecamp_community_images`     `communities`

  Member 4          Event images      `onecamp_event_images`         `events`

  Member 5          Chat images       `onecamp_chat_images`          `chats`

  Member 6          Marketplace       `onecamp_marketplace_images`   `marketplace`
                    images                                           
  ------------------------------------------------------------------------------------

## 4. Flutter run command

The team provided this command as the way to pass the Cloudinary
configuration into the Flutter app:

``` bash
flutter run `
  --dart-define=CLOUDINARY_CLOUD_NAME=o5k43wz7 `
  --dart-define=CLOUDINARY_UPLOAD_PRESET=your_assigned_preset
```

Replace `your_assigned_preset` with the preset assigned to your feature.

For example, Member 2 (Feed) would run:

``` bash
flutter run `
  --dart-define=CLOUDINARY_CLOUD_NAME=o5k43wz7 `
  --dart-define=CLOUDINARY_UPLOAD_PRESET=onecamp_feed_images
```

The backtick (\`) is PowerShell's line-continuation character. If you
use a terminal that does not support PowerShell syntax, use the
equivalent command format for that terminal, or put the command on one
line.

In Dart, values passed through `--dart-define` can be read with:

``` dart
const cloudName = String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
const uploadPreset = String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET');
```

These constants read the values supplied when the app is launched. If
the values are not supplied, they will be empty strings.

## 5. Required image-upload workflow

The intended flow is:

1.  The user selects or takes an image in the OneCamp app.
2.  The Flutter feature uploads the image to Cloudinary over HTTPS.
3.  The upload request uses:
    -   The shared cloud name: `o5k43wz7`
    -   The upload preset assigned to that feature
4.  Cloudinary stores the image in the folder configured for that
    preset.
5.  Cloudinary returns information about the uploaded image, including
    its `secure_url`.
6.  The app saves that `secure_url` in the appropriate Firestore
    document.
7.  When the image needs to be displayed, the app reads the URL from
    Firestore and loads the image from Cloudinary.

### Simplified architecture

``` text
User selects an image
        |
        v
OneCamp Flutter feature
        |
        | HTTPS upload request
        | Cloud name + assigned unsigned preset
        v
Cloudinary
        |
        | Returns secure_url
        v
Flutter app
        |
        | Save image URL
        v
Cloud Firestore
        |
        | Read image URL later
        v
Display image in the app
```

**Important:** The image file itself is stored in Cloudinary. Firestore
stores the URL and any related metadata your feature needs; it does not
store the image file itself.

## 6. Team instructions

-   Use your own assigned upload preset.
-   Use the shared Cloudinary cloud name.
-   Upload images using HTTPS.
-   Store the returned `secure_url` in the appropriate Firestore
    document.
-   Do not use Firebase Storage for this project.
-   Do not create separate Cloudinary accounts.
-   Do not share or commit the Cloudinary API Secret.
-   Do not change shared presets or shared media services without
    coordinating with the team.
-   Integrate and test image uploading within your own assigned feature.

The team leader will coordinate the shared Cloudinary configuration and
shared integration.

## 7. Why only three dashboard users are not a problem

The Cloudinary free plan allows only three dashboard users, while the
team has six members.

The team does not need to invite all six members to the Cloudinary
dashboard to upload images. The team leader can configure the account
and create the unsigned upload presets. Each Flutter app can then use
its assigned preset and the cloud name to upload images.

In other words:

-   **Dashboard access** means being able to sign in to and manage the
    Cloudinary account.
-   **Using an upload preset** means the application can send an upload
    request using a preset configured by the account owner.

These are different things. Team members can use their assigned presets
without each having their own Cloudinary dashboard login.

## 8. What is an unsigned upload preset?

A Cloudinary upload preset is a saved configuration that tells
Cloudinary how to handle uploads. The team has configured separate
presets for the different OneCamp features.

An **unsigned** preset allows the client application (in this case, the
Flutter app) to upload without generating a server-side signature for
each upload.

That is convenient for a mobile application, but it also means the
preset must be configured carefully. Anyone who obtains the cloud name
and preset name may be able to attempt uploads using that preset,
subject to the preset's restrictions and Cloudinary's account controls.

The preset name is not an API secret. However, an unsigned preset is not
a substitute for a secure backend or strong abuse controls. Restrict the
preset as much as Cloudinary allows, for example by limiting allowed
formats and file sizes, and avoid allowing unnecessary upload options.

## 9. Security: what must not be exposed

Do not put the **Cloudinary API Secret** in Flutter code,
`--dart-define`, GitHub, or any client-side configuration. A mobile app
can be inspected, so secrets embedded in it cannot be kept secret.

The team message specifically says not to share or commit the API
Secret. Follow that instruction.

The cloud name and unsigned preset name are used by the client app and
are not equivalent to the API Secret. Still, they should be treated as
public configuration, not as authentication credentials.

If stronger upload security or more advanced authorization is required,
uploads should be mediated by a trusted backend that can generate signed
upload parameters.

## 10. What you should do for your own feature

1.  Find your member number and assigned feature in the preset table.
2.  Copy the exact preset name.
3.  Run Flutter with the shared cloud name and your assigned preset.
4.  Implement the upload in your feature using HTTPS.
5.  Read the `secure_url` from Cloudinary's successful upload response.
6.  Save that URL in the correct Firestore document.
7.  Test uploading and displaying an image in your feature.
8.  Coordinate with the team before changing any shared media service or
    configuration.

## 11. Important distinction: Cloudinary and Firebase have different jobs

  -----------------------------------------------------------------------
  Service                             OneCamp responsibility
  ----------------------------------- -----------------------------------
  Firebase Authentication             User registration and login

  Cloud Firestore                     App data, such as profiles, posts,
                                      event details, and image URLs

  Cloudinary                          Actual image hosting and delivery

  Flutter                             Selects images, sends upload
                                      requests, saves returned URLs, and
                                      displays images
  -----------------------------------------------------------------------

Cloudinary replaces **Firebase Storage for image hosting**. It does not
replace Firebase Authentication or Cloud Firestore.

------------------------------------------------------------------------

# Explanation in simple terms

Think of Cloudinary as the place where OneCamp keeps the actual image
files.

For example, when a student uploads a profile picture:

1.  The Flutter app sends the picture to Cloudinary.
2.  Cloudinary stores the picture in the `profiles` folder using Member
    1's preset.
3.  Cloudinary gives the app a URL, such as a secure HTTPS image
    address.
4.  The app saves that address in the student's profile document in
    Firestore.
5.  Later, the app reads the address from Firestore and displays the
    picture.

So there are two separate things:

-   **Cloudinary stores the image.**
-   **Firestore stores the address of the image.**

The six members share one Cloudinary account, but each member uses a
different preset so their uploads are separated by feature.

## One thing to confirm with the team leader

The message says each preset has its own folder. Confirm that each
unsigned preset is actually configured in Cloudinary to save uploads to
its listed folder, and that the preset restrictions are appropriate. The
Flutter command only selects a preset; it does not create the folder or
configure the preset.

Also confirm the agreed Firestore field names and document locations for
image URLs. The message tells the team to save `secure_url`, but it does
not define the exact Firestore schema or field names.
