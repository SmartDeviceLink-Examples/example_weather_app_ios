//  SDLShow.h
//

#import "SDLRPCRequest.h"

#import "SDLTextAlignment.h"
#import "SDLMetadataType.h"

@class SDLImage;
@class SDLSoftButton;
@class SDLMetadataTags;


/**
 * Updates the application's display text area, regardless of whether or not
 * this text area is visible to the user at the time of the request. The
 * application's display text area remains unchanged until updated by subsequent
 * calls to Show
 * <p>
 * The content of the application's display text area is visible to the user
 * when the application
 * is FULL or LIMITED, and the
 * SDLSystemContext=MAIN and no
 * SDLAlert is in progress
 * <p>
 * The Show operation cannot be used to create an animated scrolling screen. To
 * avoid distracting the driver, Show commands cannot be issued more than once
 * every 4 seconds. Requests made more frequently than this will be rejected
 * <p>
 * <b>HMILevel needs to be FULL, LIMITED or BACKGROUND</b>
 * </p>
 *
 * Since SmartDeviceLink 1.0
 * See SDLAlert SDLSetMediaClockTimer
 */

NS_ASSUME_NONNULL_BEGIN

@interface SDLShow : SDLRPCRequest

- (instancetype)initWithMainField1:(nullable NSString *)mainField1 mainField2:(nullable NSString *)mainField2 alignment:(nullable SDLTextAlignment)alignment;

- (instancetype)initWithMainField1:(nullable NSString *)mainField1 mainField1Type:(nullable SDLMetadataType)mainField1Type mainField2:(nullable NSString *)mainField2 mainField2Type:(nullable SDLMetadataType)mainField2Type alignment:(nullable SDLTextAlignment)alignment;

- (instancetype)initWithMainField1:(nullable NSString *)mainField1 mainField2:(nullable NSString *)mainField2 mainField3:(nullable NSString *)mainField3 mainField4:(nullable NSString *)mainField4 alignment:(nullable SDLTextAlignment)alignment;

- (instancetype)initWithMainField1:(nullable NSString *)mainField1 mainField1Type:(nullable SDLMetadataType)mainField1Type mainField2:(nullable NSString *)mainField2 mainField2Type:(nullable SDLMetadataType)mainField2Type mainField3:(nullable NSString *)mainField3 mainField3Type:(nullable SDLMetadataType)mainField3Type mainField4:(nullable NSString *)mainField4 mainField4Type:(nullable SDLMetadataType)mainField4Type alignment:(nullable SDLTextAlignment)alignment;

- (instancetype)initWithMainField1:(nullable NSString *)mainField1 mainField2:(nullable NSString *)mainField2 alignment:(nullable SDLTextAlignment)alignment statusBar:(nullable NSString *)statusBar mediaClock:(nullable NSString *)mediaClock mediaTrack:(nullable NSString *)mediaTrack;

- (instancetype)initWithMainField1:(nullable NSString *)mainField1 mainField2:(nullable NSString *)mainField2 mainField3:(nullable NSString *)mainField3 mainField4:(nullable NSString *)mainField4 alignment:(nullable SDLTextAlignment)alignment statusBar:(nullable NSString *)statusBar mediaClock:(nullable NSString *)mediaClock mediaTrack:(nullable NSString *)mediaTrack graphic:(nullable SDLImage *)graphic softButtons:(nullable NSArray<SDLSoftButton *> *)softButtons customPresets:(nullable NSArray<NSString *> *)customPresets textFieldMetadata:(nullable SDLMetadataTags *)metadata;

/**
 * @abstract The text displayed in a single-line display, or in the upper display
 * line in a two-line display
 * @discussion The String value representing the text displayed in a
 *            single-line display, or in the upper display line in a
 *            two-line display
 *            <p>
 *            <b>Notes: </b>
 *            <ul>
 *            <li>If this parameter is omitted, the text of mainField1 does
 *            not change</li>
 *            <li>If this parameter is an empty string, the field will be
 *            cleared</li>
 *            </ul>
 */
@property (strong, nonatomic, nullable) NSString *mainField1;
/**
 * @abstract The text displayed on the second display line of a two-line display
 *
 * @discussion The String value representing the text displayed on the second
 *            display line of a two-line display
 *            <p>
 *            <b>Notes: </b>
 *            <ul>
 *            <li>If this parameter is omitted, the text of mainField2 does
 *            not change</li>
 *            <li>If this parameter is an empty string, the field will be
 *            cleared</li>
 *            <li>If provided and the display is a single-line display, the
 *            parameter is ignored</li>
 *            <li>Maxlength = 500</li>
 *            </ul>
 */
@property (strong, nonatomic, nullable) NSString *mainField2;
/**
 * @abstract The text displayed on the first display line of the second page
 *
 * @discussion The String value representing the text displayed on the first
 *            display line of the second page
 *            <p>
 *            <b>Notes: </b>
 *            <ul>
 *            <li>If this parameter is omitted, the text of mainField3 does
 *            not change</li>
 *            <li>If this parameter is an empty string, the field will be
 *            cleared</li>
 *            <li>If provided and the display is a single-line display, the
 *            parameter is ignored</li>
 *            <li>Maxlength = 500</li>
 *            </ul>
 * @since SmartDeviceLink 2.0
 */
@property (strong, nonatomic, nullable) NSString *mainField3;
/**
 * @abstract The text displayed on the second display line of the second page
 *
 * @discussion The String value representing the text displayed on the second
 *            display line of the second page
 *            <p>
 *            <b>Notes: </b>
 *            <ul>
 *            <li>If this parameter is omitted, the text of mainField4 does
 *            not change</li>
 *            <li>If this parameter is an empty string, the field will be
 *            cleared</li>
 *            <li>If provided and the display is a single-line display, the
 *            parameter is ignored</li>
 *            <li>Maxlength = 500</li>
 *            </ul>
 * @since SmartDeviceLink 2.0
 */
@property (strong, nonatomic, nullable) NSString *mainField4;
/**
 * @abstract The alignment that Specifies how mainField1 and mainField2 text
 * should be aligned on display
 *
 * @discussion An Enumeration value
 *            <p>
 *            <b>Notes: </b>
 *            <ul>
 *            <li>Applies only to mainField1 and mainField2 provided on this
 *            call, not to what is already showing in display</li>
 *            <li>If this parameter is omitted, text in both mainField1 and
 *            mainField2 will be centered</li>
 *            <li>Has no effect with navigation display</li>
 *            </ul>
 */
@property (strong, nonatomic, nullable) SDLTextAlignment alignment;
/**
 * @abstract Text in the Status Bar
 *
 * @discussion A String representing the text you want to add in the Status
 *            Bar
 *            <p>
 *            <b>Notes: </b><i>The status bar only exists on navigation
 *            displays</i><br/>
 *            <ul>
 *            <li>If this parameter is omitted, the status bar text will
 *            remain unchanged</li>
 *            <li>If this parameter is an empty string, the field will be
 *            cleared</li>
 *            <li>If provided and the display has no status bar, this
 *            parameter is ignored</li>
 *            </ul>
 */
@property (strong, nonatomic, nullable) NSString *statusBar;
/**
 * @abstract This property is deprecated use SetMediaClockTimer instead.
 * <p> The value for the MediaClock field using a format described in the
 * MediaClockFormat enumeration
 *
 * @discussion A String value for the MediaClock
 *            <p>
 *            <b>Notes: </b><br/>
 *            <ul>
 *            <li>Must be properly formatted as described in the
 *            MediaClockFormat enumeration</li>
 *            <li>If a value of five spaces is provided, this will clear
 *            that field on the display (i.e. the media clock timer field
 *            will not display anything)</li>
 *            </ul>
 */
@property (strong, nonatomic, nullable) NSString *mediaClock;
/**
 * @abstract The text in the track field
 *
 * @discussion A String value disaplayed in the track field
 *            <p>
 *            <b>Notes: </b><br/>
 *            <ul>
 *            <li>If parameter is omitted, the track field remains unchanged</li>
 *            <li>If an empty string is provided, the field will be cleared</li>
 *            <li>This field is only valid for media applications on navigation displays</li>
 *            </ul>
 */
@property (strong, nonatomic, nullable) NSString *mediaTrack;
/**
 * @abstract An image to be shown on supported displays
 *
 * @discussion The value representing the image shown on supported displays
 *            <p>
 *            <b>Notes: </b>If omitted on supported displays, the displayed
 *            graphic shall not change<br/>
 * @since SmartDeviceLink 2.0
 */
@property (strong, nonatomic, nullable) SDLImage *graphic;
/**
 * @abstract An image to be shown on supported displays
 *
 * @discussion The value representing the image shown on supported displays
 *            <p>
 *            <b>Notes: </b>If omitted on supported displays, the displayed
 *            graphic shall not change<br/>
 * @since SmartDeviceLink 2.0
 */
@property (strong, nonatomic, nullable) SDLImage *secondaryGraphic;
/**
 * @abstract The the Soft buttons defined by the App
 *
 * @discussion A Vector value represemting the Soft buttons defined by the
 *            App
 *            <p>
 *            <b>Notes: </b><br/>
 *            <ul>
 *            <li>If omitted on supported displays, the currently displayed
 *            SoftButton values will not change</li>
 *            <li>Array Minsize: 0</li>
 *            <li>Array Maxsize: 8</li>
 *            </ul>
 *
 * @since SmartDeviceLink 2.0
 */
@property (strong, nonatomic, nullable) NSArray<SDLSoftButton *> *softButtons;
/**
 * @abstract The Custom Presets defined by the App
 *
 * @discussion A Vector value representing the Custom Presets defined by the
 *            App
 *            <p>
 *            <ul>
 *            <li>If omitted on supported displays, the presets will be shown as not defined</li>
 *            <li>Array Minsize: 0</li>
 *            <li>Array Maxsize: 6</li>
 *            </ul>
 * @since SmartDeviceLink 2.0
 */
@property (strong, nonatomic, nullable) NSArray<NSString *> *customPresets;

/**
 * @abstract Text Field Metadata
 *
 * @discussion A Vector value representing the Custom Presets defined by the
 *            App
 *            <p>
 *            App defined metadata information. See MetadataStruct. Uses mainField1, mainField2, mainField3, mainField4.
 *            If omitted on supported displays, the currently set metadata tags will not change.
 *            If any text field contains no tags or the none tag, the metadata tag for that textfield should be removed.
 * @since SmartDeviceLink 2.0
 */
@property (strong, nonatomic, nullable) SDLMetadataTags *metadataTags;

@end

NS_ASSUME_NONNULL_END
