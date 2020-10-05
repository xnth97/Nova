class Nova {
  // Navigation

  static show(options) {
    let msg = {type: 'show'};
    msg = Object.assign(msg, options);
    window.webkit.messageHandlers.navigation.postMessage(msg);
  }

  static present(options, nav) {
    let msg = {type: 'present'};
    msg = Object.assign(msg, options);
    if (arguments.length === 2 && nav === true) {
      msg.nav = 'true';
    }
    window.webkit.messageHandlers.navigation.postMessage(msg);
  }

  static pop() {
    window.webkit.messageHandlers.navigation.postMessage({
      type: 'pop',
    });
  }

  static dismiss() {
    window.webkit.messageHandlers.navigation.postMessage({
      type: 'dismiss',
    });
  }

  // Bridge

  static callNative(func, param, cls) {
    let msg = {func: func};
    if (param) {
      msg.param = param;
    }
    if (cls) {
      msg.class = cls;
    }
    return new NovaBridge().postMessage('bridge', msg);
  }

  // UI

  static alert(title, message, actions) {
    Nova.p_alert('alert', title, message, actions);
  }

  static actionSheet(title, message, actions) {
    Nova.p_alert('actionSheet', title, message, actions);
  }

  static p_alert(type, title, message, actions) {
    let options = {};
    if (title !== undefined && title !== null) {
      options.title = title;
    }
    if (message !== undefined && message !== null) {
      options.message = message;
    }
    if (actions !== undefined && actions !== null) {
      options.actions = actions;
    }
    let msg = {};
    msg[type] = options;
    window.webkit.messageHandlers.ui.postMessage(msg);
  }

  static setLeftBarButton(options) {
    if (options instanceof Array) {
      window.webkit.messageHandlers.ui.postMessage({
        leftBarButtons: options,
      });
    } else {
      window.webkit.messageHandlers.ui.postMessage({
        leftBarButton: options,
      });
    }
  }

  static setRightBarButton(options) {
    if (options instanceof Array) {
      window.webkit.messageHandlers.ui.postMessage({
        rightBarButtons: options,
      });
    } else {
      window.webkit.messageHandlers.ui.postMessage({
        rightBarButton: options,
      });
    }
  }

  static setOrientation(orientation) {
    window.webkit.messageHandlers.ui.postMessage({
      orientation: orientation,
    });
  }

  static activity(options) {
    window.webkit.messageHandlers.ui.postMessage({
      activity: options
    });
  }

  // Data
  static save(key, value) {
    window.webkit.messageHandlers.data.postMessage({
      action: 'save',
      key: key,
      value: value,
    });
  }

  static load(key, defaultValue) {
    let msg = {
      action: 'load',
      key: key,
      default: defaultValue,
    };
    return new NovaBridge().postMessage('data', msg);
  }

  static remove(key) {
    window.webkit.messageHandlers.data.postMessage({
      action: 'remove',
      key: key,
    });
  }
}

let _novaBridgeInstance = null;

class NovaBridge {
  constructor() {
    if (_novaBridgeInstance) {
      return _novaBridgeInstance;
    }

    this.handlers = {};
    this.currentId = 0;
    _novaBridgeInstance = this;
  }

  postMessage(webkitHandler, message) {
    return new Promise((resolve, reject) => {
      let msg = {id: `${this.currentId}`};
      this.handlers[`${this.currentId}`] = {resolve, reject};
      this.currentId ++;
      msg = Object.assign(msg, message);
      window.webkit.messageHandlers[webkitHandler].postMessage(msg);
    });
  }

  handleMessage(id, error, data) {
    if (error) {
      this.handlers[id].reject(error);
    } else {
      this.handlers[id].resolve(data);
    }
    delete this.handlers[id];
  }
}