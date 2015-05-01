class ExampleComponent extends BlazeComponent {
  template() {
    // We register the component under a different name.
    return 'ExampleComponent';
  }

  onCreated() {
    this.counter = new ReactiveVar(0);
  }

  events() {
    return [{
      'click .increment': this.onClick
    }];
  }

  onClick(event) {
    this.counter.set(this.counter.get() + 1);
  }

  customHelper() {
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
}

ExampleComponent.register('ExampleComponentES6');

var MyComponent = BlazeComponent.getComponent('MyComponent');
class OurComponent extends MyComponent {
  template() {
    // By default it would use "OurComponentES6" name.
    return 'MyComponent';
  }

  values() {
    return '>>>' + super.values() + '<<<';
  }
}

OurComponent.register('OurComponentES6');
