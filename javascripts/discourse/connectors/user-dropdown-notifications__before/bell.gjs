import Component from "@glimmer/component";
import dIcon from "discourse-common/helpers/d-icon";
import { service } from "@ember/service";

export default class bellIcon extends Component {
  @service site;
  <template>
    {{#if this.site.mobileView}}
      {{dIcon "bell"}}
    {{/if}}
  </template>
}
