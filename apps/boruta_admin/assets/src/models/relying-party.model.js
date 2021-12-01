import axios from 'axios'

const defaults = {
  name: null,
  type: 'internal',
  errors: null
}

const assign = {
  id: function ({ id }) { this.id = id },
  name: function ({ name }) { this.name = name },
  type: function ({ type }) { this.type = type }
}

class RelyingParty {
  constructor (params = {}) {
    Object.assign(this, defaults)

    Object.keys(params).forEach((key) => {
      this[key] = params[key]
      assign[key].bind(this)(params)
    })
  }

  get baseUrl () {
    const { scheme, host, port } = this

    return `${scheme}://${host}:${port}`
  }

  save () {
    // TODO trigger validate
    let response
    const { id, serialized } = this
    if (id) {
      response = this.constructor.api().patch(`/${id}`, { relying_party: serialized })
    } else {
      response = this.constructor.api().post('/', { relying_party: serialized })
    }

    return response
      .then(({ data }) => {
        const params = data.data

        Object.keys(params).forEach((key) => {
          this[key] = params[key]
          assign[key].bind(this)(params)
        })
        return this
      })
      .catch((error) => {
        const { errors } = error.response.data
        this.errors = errors
        throw errors
      })
  }

  destroy () {
    return this.constructor.api().delete(`/${this.id}`)
  }

  get serialized () {
    const { id, name, type } = this

    return {
      id,
      name,
      type
    }
  }

  static api () {
    const accessToken = localStorage.getItem('access_token')

    return axios.create({
      baseURL: `${window.env.VUE_APP_BORUTA_BASE_URL}/api/relying-parties`,
      headers: { 'Authorization': `Bearer ${accessToken}` }
    })
  }

  static all () {
    return this.api().get('/').then(({ data }) => {
      return data.data.map((relyingParty) => new RelyingParty(relyingParty))
    })
  }

  static get (id) {
    return this.api().get(`/${id}`).then(({ data }) => {
      return new RelyingParty(data.data)
    })
  }
}

export default RelyingParty