import Component from "@glimmer/component";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import { action } from "@ember/object";

export default class hubTab extends Component {
  @service router;
  @service site;
  @service header;
  @service capabilities;

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
