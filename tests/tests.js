var ExampleComponent = BlazeComponent.extendComponent({
  template: function () {
    // We register the component under a different name.
    return 'ExampleComponent';
  },

  onCreated: function () {
    this.counter = new ReactiveVar(0);
  },

  events: function () {
    return [{
      'click .increment': this.onClick
    }];
  },

  onClick: function (event) {
    this.counter.set(this.counter.get() + 1);
  },

  customHelper: function () {
    if (this.counter.get() > 10) {
      return "Too many times";
    }
    else if (this.counter.get() === 10) {
      return "Just enough";
    }
    else {
      return "Click more";
    }
  }
// We use ExampleComponentJS here for JavaScript implementation.
}).register('ExampleComponentJS');

var MyComponent = BlazeComponent.getComponent('MyComponent');
var OurComponent = MyComponent.extendComponent({
  template: function () {
    // By default it would use "OurComponentJS" name.
    return 'MyComponent';
  },

  values: function () {
    return '>>>' + OurComponent.__super__.values.call(this) + '<<<';
  }
}).register('OurComponentJS');
