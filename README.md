# Today Was a Good Day - Journaling App

Welcome to "Today Was a Good Day," your personalized journaling app designed to make the process effortless and enjoyable. This iPhone application leverages photos as the foundation for all journal entries, reducing user input and making journaling a seamless part of your day.

## Application Overview

The app focuses on core features, allowing users to create, edit, and delete journal entries effortlessly. Here's an overview of the main screens:

### Home Screen

- Utilizes a table or collection view controller to display journal entries.
- Cells contain a thumbnail image, a text blurb, and the date, sectioned by month.
- Integrated search bar in the navigation bar for filtering entries by text or tags.
- Navigation bar buttons for Settings, creating an Entry, or accessing the Map View.

### Map Screen

- Displays all journal entries on a map with clustering for dense locations.
- Tapping on a cluster shows entries close to the tapped point.
- Leverages iOS 11 map clustering feature for a user-friendly experience.

### Settings Screen

- Allows users to access app-specific settings.
- Displays the user's name from the iCloud user account.
- Includes buttons for Sync, Privacy (with Touch ID), and On This Day notifications.

### Journal Entry Screen

- Enables users to create an entry requiring a photo.
- Photo provides metadata, including location and creation date.
- Allows editing of photo, date, and text.

## Data and Sync

- Follows an "offline first" approach with local data persistence as the primary goal.
- Syncs opportunistically through CloudKit.
- Uses Codable protocol to store journal entries as JSON to disk.
- Images are cached locally.
- Utilizes CloudKit subscriptions for efficient syncing between devices.

## Extensions

- Includes a photo share extension and a widget extension for seamless entry creation.
- Supports adding an entry directly from the Photos app.

## Attributions

- Logo: [Cute Travel Icon](https://www.vecteezy.com/png/11003373-cute-travel-icon)

### Notes

- The commit is not able to take the YOLOv3.mlmodel even through LFS.
- Model taken from [Apple's Machine Learning Models](https://developer.apple.com/machine-learning/models/).

## Additional Information

- This project was developed using Xcode, Objective-C and Swift.
- For issues or questions, contact [(Jas) Jaswitha](mailto:jaswithareddyguntaka@gmail.com).

Feel free to explore, contribute, and make the journaling experience even better! Happy journaling! 📔✨
