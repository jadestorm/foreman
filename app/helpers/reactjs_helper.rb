require 'webpack-rails'
module ReactjsHelper
  # Mount react component in views
  # Params:
  # +name+:: the component name from the componentRegistry
  # +props+:: props to pass to the component
  #          valid value types: Hash, json-string, nil
  def react_component(name, props = {})
    props = props.to_json if props.is_a?(Hash)

    content_tag('foreman-react-component', '', :name => name, :data => { props: props })
  end

  def webpacked_plugins_with_global_css
    global_css_tags(global_plugins_list).join.html_safe
  end

  def webpacked_plugins_js_for(*plugin_names)
    js_tags_for(select_requested_plugins(plugin_names)).join.html_safe
  end

  def webpacked_plugins_with_global_js
    global_js_tags(global_plugins_list).join.html_safe
  end

  def webpacked_plugins_css_for(*plugin_names)
    css_tags_for(select_requested_plugins(plugin_names)).join.html_safe
  end

  def select_requested_plugins(plugin_names)
    available_plugins = Foreman::Plugin.with_webpack.map(&:id)
    missing_plugins = plugin_names - available_plugins
    if missing_plugins.any?
      logger.error { "Failed to include webpack assets for plugins: #{missing_plugins}" }
      raise ::Foreman::Exception.new("Failed to include webpack assets for plugins: #{missing_plugins}") if Rails.env.development?
    end
    plugin_names & available_plugins
  end

  def js_tags_for(requested_plugins)
    requested_plugins.map do |plugin|
      javascript_include_tag(*webpack_asset_paths(plugin.to_s, :extension => 'js'))
    end
  end

  def global_js_tags(requested_plugins)
    requested_plugins.map do |plugin|
      plugin[:files].map do |file|
        javascript_include_tag(*webpack_asset_paths("#{plugin[:id]}:#{file}", :extension => 'js'), :defer => "defer")
      end
    end
  end

  def global_css_tags(requested_plugins)
    requested_plugins.map do |plugin|
      plugin[:files].map do |file|
        stylesheet_link_tag(*webpack_asset_paths("#{plugin[:id]}:#{file}", :extension => 'css'))
      end
    end
  end

  def css_tags_for(requested_plugins)
    requested_plugins.map do |plugin|
      stylesheet_link_tag(*webpack_asset_paths(plugin.to_s, :extension => 'css'))
    end
  end

  private

  def global_plugins_list
    Foreman::Plugin.with_global_js.map { |plugin| { id: plugin.id, files: plugin.global_js_files } }
  end
end
