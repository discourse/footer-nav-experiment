import Component from "@glimmer/component";
import { action } from "@ember/object";
import DButton from "discourse/components/d-button";
import { postRNWebviewMessage } from "discourse/lib/utilities";

export default class HubTab extends Component {
  static shouldRender(args, context) {
    return context.capabilities.isAppWebview;
  }

  @action
  dismiss() {
    postRNWebviewMessage("dismiss", true);
  }

  <template>
    <div class="hub-tab">
      <DButton
        @action={{this.dismiss}}
        @icon="fab-discourse"
        @title={{themePrefix "mobile_footer.return_to_hub"}}
        class="btn-transparent no-text"
      />
    </div>
  </template>
}
