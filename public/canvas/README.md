# bCourses customizations

In order to apply the bCourses skin and bCourses customizations, go to the Theme Editor within the Account Administration space.

Configure the following values:

## Global Branding

| Property              | Value   |
|-----------------------|---------|
| Primary Color         | #003262 |
| Primary Button        | #3b7ea1 |
| Primary Button Text   | #ffffff |
| Secondary Button      | #3b7ea1 |
| Secondary Button Text | #ffffff |
| Link                  | #3b7ea1 |

## Global Navigation

| Property              | Value                          |
|-----------------------|--------------------------------|
| Nav Background        | #003262                        |
| Nav Icon              | #ffffff                        |
| Nav Icon Active       | #003262                        |
| Nav Text              | #ffffff                        |
| Nav Text Active       | #003262                        |
| Nav Avatar Border     | #ffffff                        |
| Nav Badge             | #ffffff                        |
| Nav Badge Text        | #003262                        |
| Nav Logo Background   | #003262                        |
| Nav Logo              | `images/bcourses_lefthand.png` |

## Watermarks & Other Images

| Property               | Value                                |
|------------------------|--------------------------------------|
| Watermark              | N/A                                  |
| Watermark Opacity      | 100%                                 |
| Favicon                | `images/favicon.ico`                 |
| Mobile Homescreen Icon | `images/bcourses_ios_icon.png`       |
| Windows Tile Color     | #003262                              |
| Windows Tile: Square   | `images/bcourses_windows_square.png` |
| Windows Tile: Wide     | `images/bcourses_windows_wide.png`   |
| Right Sidebar Logo     | `images/bcourses_righthand.png`      |

## Upload

| Property               | Value                     |
|----------------------- |---------------------------|
| JavaScript file        | `canvas-customization.js` |

**NOTE:** The `canvas-customization.js` file will by default load resources from and make API requests to CalCentral production. In order to point to a different CalCentral server, the `window.CALCENTRAL` property in the `canvas-customization.js` file should be updated to point to that server.
