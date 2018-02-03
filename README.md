# Nova

A lightweight HTML container for iOS.

# Features

* Full-screen native-like container
* JavaScript injection
* Automatically loads remote URL/local resources
* Modulized MessageHandlers
* Dynamically initialize ViewControllers and pass parameters
* JavaScript callback from native UI components

# Screenshot

![](Screenshots/1.png)

# Usage

## Basic

Simply use `NovaRootViewController` or its subclass, set its `url` property to a local HTML resource or a remote website.

## Navigation

### Basic Usage

```javascript
nova.navigation.postMessage({ type: 'show', url: 'navigation.html', title: 'Navigation' });
```

`type` parameter has 4 values: `show`, `present`, `pop` and `dismiss`. Each calls corresponding methonds in UIKit. Another reserved parameter is `nav`, which is used with `present` and if set to `true`, the presented ViewController will be within a `UINavigationController`.

By default, this method will initialize a `NovaRootViewController` instance. Parameters other than `type`, `class`, `nav` would be automatically added to the new instance.

### Custom Class

```javascript
nova.navigation.postMessage({type: 'show', class: 'DemoViewController'});
```

Pass a `class` parameter. This method will initialize a new instance of `class` that you passed. Also, parameters other than `type`, `class`, `nav` would be automatically added to the instance. Please make sure that `class` is a subclass of `UIViewController`.

## UI

### Alert

#### Default Alert

```javascript
alert('message here');
```

#### Custom Alert

```javascript
nova.ui.postMessage({ alert: {
    title: 'Hello', 
    message: 'Hello Again!', 
    actions: [
        {
            title: 'OK', 
            callback: 'alert(\'Callback from OK action\');' 
        }, {
            title: 'Cancel', 
            callback: 'alert(\'Callback from Cancel action\');', 
            style: 'destructive'
        }
    ]
}});
```

`style` parameter has 3 possible values: `cancel`, `destructive` and `default`. Each of them is the same with corresponding `UIAlertActionStyle` enum value. 

### ActionSheet

```javascript
nova.ui.postMessage({ actionSheet: { 
    title: 'Hello', 
    message: 'Hello Again!', 
    actions: [
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
        }
    ]
}});
```

Same as alert.

### Orientation

```javascript
nova.ui.postMessage({ orientation: 'portrait' });
```

`orientation` parameter has 3 values: `portrait`, `landscapeLeft` and `landscapeRight`.


# TODO List

- [ ] Provide more native UIKit APIs
- [ ] JSCore to process JSValue and ObjC objects
- [ ] Safe area
- [ ] Runtime method invocation
- [ ] Swift compatibility
- [ ] UA
