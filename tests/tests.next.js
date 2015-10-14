// Example from the README.

class ExampleComponent extends BlazeComponent {
  template() {
    // We register the component under a different name.
    return 'ExampleComponent';
  }

  // Life-cycle hook to initialize component's state.
  onCreated() {
    // It is a good practice to always call super.
    super.onCreated();
    this.counter = new ReactiveField(0);
  }

  // Mapping between events and their handlers.
  events() {
    // It is a good practice to always call super.
    return super.events().concat({
      // You could inline the handler, but the best is to make
      // it a method so that it can be extended later on.
      'click .increment': this.onClick
    });
  }

  onClick(event) {
    this.counter(this.counter() + 1);
  }

  // Any component's method is available as a template helper in the template.
  customHelper() {
    if (this.counter() > 10) {
      return "Too many times";
    }
    else if (this.counter() === 10) {
      return "Just enough";
    }
    else {
      return "Click more";
    }
  }
}

// Register a component so that it can be included in templates. It also
// gives the component the name. The convention is to use the class name.
ExampleComponent.register('ExampleComponentES2015');

var MyComponent = BlazeComponent.getComponent('MyComponent');
class OurComponent extends MyComponent {
  template() {
    // By default it would use "OurComponentES2015" name.
    return 'MyComponent';
  }

  values() {
    return '>>>' + super.values() + '<<<';
  }
}

OurComponent.register('OurComponentES2015');
