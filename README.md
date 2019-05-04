# Nova

![](https://img.shields.io/cocoapods/v/Nova.svg)

A lightweight HTML container for iOS.

# Features

* Full-screen native-like container
* JavaScript injection
* Automatically loads remote URL/local resources
* Modulized MessageHandlers
* Dynamically initialize ViewControllers and pass parameters
* JavaScript callback from native UI components
* Simple key-value data persistence
* Invoke native Objective-C methods and callback in JavaScript

# Screenshot

![](Screenshots/1.png)

# Usage

## Install

`pod install nova`

## Basic

Simply use `NovaRootViewController` or its subclass, and set its `url` property to a local HTML resource or a remote website.

## Navigation

### Basic Usage

```javascript
Nova.show({ url: 'navigation.html', title: 'Navigation' });
Nova.present({ url: 'navigation.html', title: 'Navigation' }, true);
Nova.pop();
Nova.dismiss();
```

For navigation there are 4 methods: `show`, `present`, `pop` and `dismiss`, each calls corresponding methonds in UIKit. The second parameter of `present` method is `nav`, which if set to `true` the presented ViewController will be contained within a `UINavigationController`.

The first parameter in `show` and `present` is a dictionary that is used to construct the ViewController. By default, this method will initialize a `NovaRootViewController` instance. Keys in dictionary other than `class` would be automatically added to the new instance through ObjC runtime.

### Custom Class

```javascript
Nova.show({ class: 'DemoViewController' });
```

This method will initialize a new instance of `class` that you passed. Also, parameters other than `class` would be automatically added to the instance through ObjC runtime. Please make sure that `class` is a subclass of `UIViewController`.

## Bridge

Nova allows you to directly execute Objective-C native methods and use the return value as parameters in JavaScript callback functions.

### Basic Usage

```javascript
Nova.callNative('getSystemInfo', null, 'updateUI');
```

This would execute the `getSystemInfo:` method in current `NovaRootViewController` instance, and pass its return value to `updateUI()` function in JavaScript. Note that you may want to use your own subclass of `NovaRootViewController` while invoking native functions.

### Class and Parameters

```javascript
Nova.callNative('getSystemInfo:', 'aParameter', 'updateUI', 'TestClass');
```

This would execute the class method `[TestClass getSystemInfo:aParameter]`, and pass its return value to `updateUI()` function in JavaScript. Note that currently only ONE parameter is supported. Please design your method properly.

When using parameters, please make sure the first parameter is the string representation of a `SEL` selector. The ':' symbol is required. Other arguments are optional.

## UI

### Alert

#### Default Alert

```javascript
alert('message here');
```

The default title is the application's bundle display name. To change this, simply modify the `alertTitle` property of your `NovaRootViewController` class.

#### Custom Alert

```javascript
Nova.alert('Hello', 'Hello Again!', [
    {
        title: 'OK', 
        callback: 'alert(\'Callback from OK action\');' 
    }, {
        title: 'Cancel', 
        callback: 'alert(\'Callback from Cancel action\');', 
        style: 'destructive'
    }
]);
```

`style` parameter has 3 possible values: `cancel`, `destructive` and `default`. Each of them is the same with corresponding `UIAlertActionStyle` enum value. 

The `callback` parameter can also be replaced with a `bridge` parameter, which should be a dictionary that is same as described in __Bridge__ section.

### ActionSheet

```javascript
Nova.actionSheet('Hello', 'Hello Again', [
    {
        title: 'First', 
        callback: 'alert(\'Callback from First action\');' 
    }, { 
        title: 'Second', 
        callback: 'alert(\'Callback from Second action\');' 
    }, { 
        title: 'Destructive', 
        callback: 'alert(\'Callback from Destructive action\');', 
        style: 'destructive' 
    }, { 
        title: 'Cancel', 
        style: 'cancel' 
    } 
]);
```

Same as alert.

### NavigationBar Button

```javascript
Nova.setRightBarButton({
    style: 'action', 
    callback: 'alert(\'This is a UIBarButtonItem\');' 
});
```

Besides `setRightBarButton`, you can also use `setLeftBarButton`, which, of course, sets the left UIBarButtonItem of the NavigationBar.

You can either use `style` or `title` parameter to customize the button, but only one parameter will make effect, which by default is `title`. For `style` parameter, it will be casted to `UIBarButtonSystem` enum, and there's a very direct mapping:

```objective-c
@{
    @"add": @(UIBarButtonSystemItemAdd),
    @"done": @(UIBarButtonSystemItemDone),
    @"cancel": @(UIBarButtonSystemItemCancel),
    @"edit": @(UIBarButtonSystemItemEdit),
    @"save": @(UIBarButtonSystemItemSave),
    @"camera": @(UIBarButtonSystemItemCamera),
    @"trash": @(UIBarButtonSystemItemTrash),
    @"reply": @(UIBarButtonSystemItemReply),
    @"action": @(UIBarButtonSystemItemAction),
    @"organize": @(UIBarButtonSystemItemOrganize),
    @"compose": @(UIBarButtonSystemItemCompose),
    @"refresh": @(UIBarButtonSystemItemRefresh),
    @"bookmarks": @(UIBarButtonSystemItemBookmarks),
    @"search": @(UIBarButtonSystemItemSearch),
    @"stop": @(UIBarButtonSystemItemStop),
    @"play": @(UIBarButtonSystemItemPlay),
    @"pause": @(UIBarButtonSystemItemPause),
    @"redo": @(UIBarButtonSystemItemRedo),
    @"undo": @(UIBarButtonSystemItemUndo),
    @"rewind": @(UIBarButtonSystemItemRewind),
    @"fastforward": @(UIBarButtonSystemItemFastForward)
}
```

The `callback` parameter can also be replaced with `bridge`.

### Multiple NavigationBar Buttons

```javascript
Nova.setRightBarButton([{
    style: 'add', 
    bridge: {
        func: 'getSystemInfo:',
        callback: 'updateUI',
        param: 'Another additional string',
    }
}, {
    style: 'action', 
    callback: 'alert(\'This is a UIBarButtonItem\');',
}]);
```

When passing an Array instead of object, multiple `UIBarButtonItem`s are automatically created and set.

### Orientation

```javascript
Nova.setOrientation('portrait');
```

`orientation` parameter has 3 values: `portrait`, `landscapeLeft` and `landscapeRight`.

## Data

### Key-Value storage

Nova provides a very simple key-value storage which allows you to save and retrieve persistent data via WKWebView. 

#### Save

Save value 'value_you_want_to_save' to key 'key_name'.

```javascript
Nova.save('key_name', 'value_you_want_to_save');
```

#### Load

Load value from key 'key_name' with default value 'default_value', then pass the loaded value to the function in callback field.

```javascript
Nova.load('key_name', 'default_value', 'alert');
```

#### Remove

Remove a key from KV storage.

```javascript
Nova.remove('key_name');
```

# TODO List

- [x] Better JavaScript APIs
- [ ] Provide more native UIKit APIs
- [ ] JSCore to process JSValue and ObjC objects
- [ ] Safe area
- [x] Runtime method invocation
- [ ] Swift compatibility
- [x] UA
- [x] Use mmap for data persistence

# License

Nova is released under the MIT License. 
