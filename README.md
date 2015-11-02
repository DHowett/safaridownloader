# Safari Download Manager

This is the [official open-source release](http://blog.howett.net/2015/11/safari-download-manager-the-end-of-an-era/) of Safari Download Manager.

Safari Download Manager is a reasonably complex tweak that adds a desktop-class download manager to Safari.app on iPhoneOS 3.1 to iOS 6.x.

If you learn something great from this code, or write anything cool using it, you 
should [send me an e-mail](mailto:dustin@howett.net)! I'd be happy to answer any 
questions you have as well, so long as you're not asking why it 
doesn't support iOS 7 and beyond ;).

## Contributors

* Dustin L. Howett (DHowett)
* francis (francis)
* Nicolas Haunold (westbaer)

## Building SDM

SDM was historically compiled using [Theos](http://iphonedevwiki.net/index.php/Theos). The Makefile expects for the `framework/` directory to contain an appropriate version of Theos; it'll probably not work exceedingly well with newer versions, though we certainly hope that it does.

## License

Safari Download Manager is available under the 3-Clause BSD License.

In short, you can do pretty much anything you want with it: bundle it in a closed-source project, modify it without releasing your changes, and so on. Your end of the bargain, however, is that you must include the license/copyright notice in binary and source redistributions, and that you can't use SDM, my name, francis's name, or the name of Cocoanuts, LLC to endorse or promote your project.

For more details, check out `LICENSE` in the root of this repository!

## Miscellany

* SDM's icon isn't included in this release.
* We used icons from the [Tango Desktop Project](http://tango.freedesktop.org/Tango_Icon_Library) for our filetype icons, and they are in the public domain.
