///|
/// Form accessibility component stories

///|
pub fn label_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "label",
      "basic",
      fn() { @components.label("Email") },
      width=15,
      height=3,
    ),
    VNodeStory::new(
      "label",
      "required",
      fn() { @components.label("Password", required=true) },
      width=15,
      height=3,
    ),
    VNodeStory::new(
      "label",
      "with_for_id",
      fn() { @components.label("Username", for_id="username", required=true) },
      width=15,
      height=3,
    ),
  ]
}

///|
pub fn fieldset_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "fieldset",
      "basic",
      fn() {
        @components.fieldset(legend="Contact Info", children=[
          @vnode.text("Name: John"),
          @vnode.text("Email: john@example.com"),
        ])
      },
      width=30,
      height=7,
    ),
    VNodeStory::new(
      "fieldset",
      "with_fields",
      fn() {
        @components.fieldset(legend="Login", children=[
          @components.label("Username", required=true),
          @vnode.text("[__________]"),
          @components.label("Password", required=true),
          @vnode.text("[**********]"),
        ])
      },
      width=25,
      height=11,
    ),
  ]
}

///|
pub fn error_message_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "error_message",
      "visible",
      fn() { @components.error_message("This field is required") },
      width=30,
      height=3,
    ),
    VNodeStory::new(
      "error_message",
      "hidden",
      fn() {
        @components.error_message("This field is required", visible=false)
      },
      width=30,
      height=3,
    ),
    VNodeStory::new(
      "error_message",
      "email_error",
      fn() { @components.error_message("Invalid email format") },
      width=30,
      height=3,
    ),
  ]
}

///|
pub fn help_text_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "help_text",
      "basic",
      fn() { @components.help_text("Enter your email address") },
      width=30,
      height=3,
    ),
    VNodeStory::new(
      "help_text",
      "format_hint",
      fn() { @components.help_text("Format: YYYY-MM-DD") },
      width=25,
      height=3,
    ),
  ]
}

///|
pub fn form_field_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "form_field",
      "basic",
      fn() {
        @components.form_field(
          label_text="Email",
          for_id="email",
          child=@vnode.text("[user@example.com]"),
        )
      },
      width=25,
      height=5,
    ),
    VNodeStory::new(
      "form_field",
      "required",
      fn() {
        @components.form_field(
          label_text="Password",
          for_id="password",
          required=true,
          child=@vnode.text("[**********]"),
        )
      },
      width=25,
      height=5,
    ),
    VNodeStory::new(
      "form_field",
      "with_help",
      fn() {
        @components.form_field(
          label_text="Username",
          for_id="username",
          help="3-20 characters, alphanumeric",
          child=@vnode.text("[__________]"),
        )
      },
      width=35,
      height=7,
    ),
    VNodeStory::new(
      "form_field",
      "with_error",
      fn() {
        @components.form_field(
          label_text="Email",
          for_id="email",
          required=true,
          error="Invalid email format",
          child=@vnode.text("[invalid-email]"),
        )
      },
      width=30,
      height=7,
    ),
  ]
}
